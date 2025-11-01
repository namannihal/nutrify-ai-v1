"""Authentication schemas"""

from typing import Optional
from pydantic import BaseModel, EmailStr, Field


class UserLogin(BaseModel):
    """User login request"""
    email: EmailStr
    password: str = Field(..., min_length=8)


class UserRegister(BaseModel):
    """User registration request"""
    email: EmailStr
    password: str = Field(..., min_length=8)
    name: str = Field(..., min_length=2, max_length=255)


class TokenResponse(BaseModel):
    """Token response"""
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class UserResponse(BaseModel):
    """User information"""
    id: str
    email: str
    name: str
    avatar_url: Optional[str] = None
    subscription_tier: str
    created_at: str
    
    class Config:
        from_attributes = True


class AuthResponse(BaseModel):
    """Authentication response with user and token"""
    user: UserResponse
    token: str  # access_token
    refresh_token: str
    token_type: str = "bearer"


class TokenPayload(BaseModel):
    """JWT token payload"""
    sub: str  # user_id
    exp: int
    type: str  # "access" or "refresh"


class GoogleAuthRequest(BaseModel):
    """Google OAuth request"""
    id_token: str


class RefreshTokenRequest(BaseModel):
    """Refresh token request"""
    refresh_token: str
