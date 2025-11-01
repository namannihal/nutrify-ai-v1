from pydantic import BaseModel
from typing import Optional, List


class AIInsightResponse(BaseModel):
    id: str
    user_id: str
    type: str
    title: str
    message: str
    explanation: str
    action_items: List[str]
    created_at: str
    priority: str

    class Config:
        from_attributes = True


class ChatMessageRequest(BaseModel):
    message: str


class ChatMessageResponse(BaseModel):
    response: str
    explanation: Optional[str] = None
