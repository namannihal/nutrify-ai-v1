"""Authentication routes"""

from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from google.oauth2 import id_token
from google.auth.transport import requests as google_requests

from app.core.database import get_db
from app.core.security import (
    verify_password,
    get_password_hash,
    create_token_pair,
    decode_token
)
from app.core.config import settings
from app.models.user import User
from app.schemas.auth import (
    UserLogin,
    UserRegister,
    TokenResponse,
    AuthResponse,
    UserResponse,
    GoogleAuthRequest,
    RefreshTokenRequest
)

router = APIRouter()


@router.post("/register", response_model=AuthResponse, status_code=status.HTTP_201_CREATED)
async def register(
    user_data: UserRegister,
    db: AsyncSession = Depends(get_db)
) -> AuthResponse:
    """Register a new user with email and password"""
    
    # Check if user already exists
    result = await db.execute(
        select(User).where(User.email == user_data.email)
    )
    if result.scalar_one_or_none():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered"
        )
    
    # Create new user
    user = User(
        email=user_data.email,
        name=user_data.name,
        password_hash=get_password_hash(user_data.password),
        subscription_tier="free"
    )
    
    db.add(user)
    await db.commit()
    await db.refresh(user)
    
    # Generate tokens
    tokens = create_token_pair(str(user.id))
    
    # Return user and tokens
    return AuthResponse(
        user=UserResponse(
            id=str(user.id),
            email=user.email,
            name=user.name,
            avatar_url=user.avatar_url,
            subscription_tier=user.subscription_tier,
            created_at=user.created_at.isoformat() if user.created_at else datetime.utcnow().isoformat()
        ),
        token=tokens["access_token"],
        refresh_token=tokens["refresh_token"],
        token_type="bearer"
    )


@router.post("/login", response_model=AuthResponse)
async def login(
    credentials: UserLogin,
    db: AsyncSession = Depends(get_db)
) -> AuthResponse:
    """Login with email and password"""
    
    # Find user
    result = await db.execute(
        select(User).where(User.email == credentials.email)
    )
    user = result.scalar_one_or_none()
    
    if not user or not user.password_hash:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password"
        )
    
    # Verify password
    if not verify_password(credentials.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password"
        )
    
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Inactive user"
        )
    
    # Update last login
    user.last_login_at = datetime.utcnow()
    await db.commit()
    
    # Generate tokens
    tokens = create_token_pair(str(user.id))
    
    # Return user and tokens
    return AuthResponse(
        user=UserResponse(
            id=str(user.id),
            email=user.email,
            name=user.name,
            avatar_url=user.avatar_url,
            subscription_tier=user.subscription_tier,
            created_at=user.created_at.isoformat() if user.created_at else datetime.utcnow().isoformat()
        ),
        token=tokens["access_token"],
        refresh_token=tokens["refresh_token"],
        token_type="bearer"
    )


@router.post("/google", response_model=TokenResponse)
async def google_auth(
    auth_data: GoogleAuthRequest,
    db: AsyncSession = Depends(get_db)
) -> TokenResponse:
    """Authenticate with Google OAuth"""
    
    if not settings.GOOGLE_CLIENT_ID:
        raise HTTPException(
            status_code=status.HTTP_501_NOT_IMPLEMENTED,
            detail="Google authentication not configured"
        )
    
    try:
        # Verify the Google ID token
        idinfo = id_token.verify_oauth2_token(
            auth_data.id_token,
            google_requests.Request(),
            settings.GOOGLE_CLIENT_ID
        )
        
        # Get user info from token
        google_id = idinfo["sub"]
        email = idinfo.get("email")
        name = idinfo.get("name", email)
        avatar_url = idinfo.get("picture")
        
        if not email:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email not provided by Google"
            )
        
        # Find or create user
        result = await db.execute(
            select(User).where(
                (User.email == email) | 
                ((User.oauth_provider == "google") & (User.oauth_id == google_id))
            )
        )
        user = result.scalar_one_or_none()
        
        if not user:
            # Create new user
            user = User(
                email=email,
                name=name,
                avatar_url=avatar_url,
                oauth_provider="google",
                oauth_id=google_id,
                email_verified=True,
                subscription_tier="free"
            )
            db.add(user)
        else:
            # Update user info
            if not user.oauth_provider:
                user.oauth_provider = "google"
                user.oauth_id = google_id
            user.email_verified = True
            user.last_login_at = datetime.utcnow()
        
        await db.commit()
        await db.refresh(user)
        
        # Generate tokens
        tokens = create_token_pair(str(user.id))
        
        return TokenResponse(**tokens)
        
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Invalid Google token: {str(e)}"
        )


@router.post("/refresh", response_model=TokenResponse)
async def refresh_token(
    refresh_data: RefreshTokenRequest,
    db: AsyncSession = Depends(get_db)
) -> TokenResponse:
    """Refresh access token using refresh token"""
    
    # Decode refresh token
    payload = decode_token(refresh_data.refresh_token)
    if not payload:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid refresh token"
        )
    
    # Check token type
    if payload.get("type") != "refresh":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token type"
        )
    
    # Get user
    user_id = payload.get("sub")
    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token payload"
        )
    
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    
    if not user or not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found or inactive"
        )
    
    # Generate new tokens
    tokens = create_token_pair(str(user.id))
    
    return TokenResponse(**tokens)


@router.post("/logout")
async def logout() -> dict[str, str]:
    """
    Logout endpoint (client should delete tokens).
    Server-side token invalidation can be implemented with Redis blacklist.
    """
    return {"message": "Successfully logged out"}
