"""Redis client for caching and session management"""

from typing import Any, Optional
import json
from redis import asyncio as aioredis

from app.core.config import settings


class RedisClient:
    """Async Redis client wrapper"""
    
    def __init__(self) -> None:
        self.redis: Optional[aioredis.Redis] = None
    
    async def connect(self) -> None:
        """Connect to Redis"""
        self.redis = await aioredis.from_url(
            settings.REDIS_URL,
            encoding="utf-8",
            decode_responses=True
        )
    
    async def close(self) -> None:
        """Close Redis connection"""
        if self.redis:
            await self.redis.close()
    
    async def get(self, key: str) -> Optional[Any]:
        """Get value from Redis"""
        if not self.redis:
            return None
        
        value = await self.redis.get(key)
        if value:
            try:
                return json.loads(value)
            except json.JSONDecodeError:
                return value
        return None
    
    async def set(
        self,
        key: str,
        value: Any,
        expire: Optional[int] = None
    ) -> bool:
        """Set value in Redis with optional expiration"""
        if not self.redis:
            return False
        
        if not isinstance(value, str):
            value = json.dumps(value)
        
        if expire:
            return await self.redis.setex(key, expire, value)
        return await self.redis.set(key, value)
    
    async def delete(self, key: str) -> bool:
        """Delete key from Redis"""
        if not self.redis:
            return False
        return await self.redis.delete(key) > 0
    
    async def exists(self, key: str) -> bool:
        """Check if key exists"""
        if not self.redis:
            return False
        return await self.redis.exists(key) > 0
    
    async def increment(self, key: str, amount: int = 1) -> int:
        """Increment counter"""
        if not self.redis:
            return 0
        return await self.redis.incrby(key, amount)
    
    async def expire(self, key: str, seconds: int) -> bool:
        """Set expiration on key"""
        if not self.redis:
            return False
        return await self.redis.expire(key, seconds)


# Global Redis client instance
redis_client = RedisClient()
