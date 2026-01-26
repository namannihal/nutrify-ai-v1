from fastapi import FastAPI, BackgroundTasks, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import uuid
import asyncio
from typing import Dict, Any, Optional

from schemas import UserProfile, NutritionPlan, WorkoutPlan
from ai_service import AIService

app = FastAPI(title="Nutrify AI Backend", version="1.0.0")

# CORS Middleware to allow Flutter app to connect
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

ai_service = AIService()

# In-memory storage for async tasks
# In production, use Redis or a database
tasks: Dict[str, Dict[str, Any]] = {}

class GenerationResponse(BaseModel):
    task_id: str
    status: str
    message: str

@app.get("/")
async def root():
    return {"message": "Nutrify AI Backend Running"}

# --- Async Generation Endpoints ---

@app.post("/api/v1/nutrition/generate-async", response_model=GenerationResponse)
async def start_nutrition_generation(profile: UserProfile, background_tasks: BackgroundTasks):
    task_id = str(uuid.uuid4())
    tasks[task_id] = {
        "type": "nutrition",
        "status": "pending",
        "progress": 0,
        "result": None,
        "error": None
    }
    
    background_tasks.add_task(process_nutrition_generation, task_id, profile)
    
    return GenerationResponse(
        task_id=task_id,
        status="pending",
        message="Nutrition plan generation started"
    )

@app.post("/api/v1/fitness/generate-async", response_model=GenerationResponse)
async def start_fitness_generation(profile: UserProfile, background_tasks: BackgroundTasks):
    task_id = str(uuid.uuid4())
    tasks[task_id] = {
        "type": "fitness",
        "status": "pending",
        "progress": 0,
        "result": None,
        "error": None
    }
    
    background_tasks.add_task(process_fitness_generation, task_id, profile)
    
    return GenerationResponse(
        task_id=task_id,
        status="pending",
        message="Fitness plan generation started"
    )

# --- Background Processors ---

async def process_nutrition_generation(task_id: str, profile: UserProfile):
    try:
        tasks[task_id]["status"] = "in_progress"
        tasks[task_id]["progress"] = 20
        
        # Simulate processing time or step updates if needed
        # In this case, we just call the AI service
        
        plan_data = await ai_service.generate_nutrition_plan(profile)
        
        tasks[task_id]["result"] = plan_data
        tasks[task_id]["status"] = "completed"
        tasks[task_id]["progress"] = 100
        
    except Exception as e:
        tasks[task_id]["status"] = "failed"
        tasks[task_id]["error"] = str(e)

async def process_fitness_generation(task_id: str, profile: UserProfile):
    try:
        tasks[task_id]["status"] = "in_progress"
        tasks[task_id]["progress"] = 20
        
        plan_data = await ai_service.generate_workout_plan(profile)
        
        tasks[task_id]["result"] = plan_data
        tasks[task_id]["status"] = "completed"
        tasks[task_id]["progress"] = 100
        
    except Exception as e:
        tasks[task_id]["status"] = "failed"
        tasks[task_id]["error"] = str(e)

# --- Status & Result Endpoints ---

@app.get("/api/v1/nutrition/generation-status/{task_id}")
async def get_nutrition_status(task_id: str):
    if task_id not in tasks:
        raise HTTPException(status_code=404, detail="Task not found")
    
    task = tasks[task_id]
    return {
        "task_id": task_id,
        "status": task["status"],
        "progress": task["progress"],
        "message": task.get("error") if task["status"] == "failed" else "Processing",
        "result_id": task_id if task["status"] == "completed" else None
    }

@app.get("/api/v1/fitness/generation-status/{task_id}")
async def get_fitness_status(task_id: str):
    if task_id not in tasks:
        raise HTTPException(status_code=404, detail="Task not found")
    
    task = tasks[task_id]
    return {
        "task_id": task_id,
        "status": task["status"],
        "progress": task["progress"],
        "message": task.get("error") if task["status"] == "failed" else "Processing",
        "result_id": task_id if task["status"] == "completed" else None
    }

# Mock endpoints for fetching the "current" plan (result of generation)
# In a real app, you would save the result to a database and fetch by ID
@app.get("/api/v1/nutrition/current-plan")
async def get_current_nutrition_plan():
    # Find latest completed nutrition task
    for task_id, task in list(tasks.items())[::-1]:
        if task["type"] == "nutrition" and task["status"] == "completed":
            return task["result"]
    raise HTTPException(status_code=404, detail="No plan found")

@app.get("/api/v1/fitness/current-plan")
async def get_current_fitness_plan():
    # Find latest completed fitness task
    for task_id, task in list(tasks.items())[::-1]:
        if task["type"] == "fitness" and task["status"] == "completed":
            return task["result"]
    raise HTTPException(status_code=404, detail="No plan found")

# --- SSE Streaming Endpoints (compatible with existing ApiService) ---
from sse_starlette.sse import EventSourceResponse

@app.get("/api/v1/nutrition/generation-status/{task_id}/stream")
async def stream_nutrition_status(task_id: str):
    async def event_generator():
        while True:
            if task_id not in tasks:
                yield {"event": "error", "data": json.dumps({"error": "Task not found"})}
                break
            
            task = tasks[task_id]
            data = {
                "status": task["status"],
                "progress": task["progress"],
                "message": task.get("error") if task["status"] == "failed" else "Processing",
                "result_id": task_id if task["status"] == "completed" else None
            }
            
            yield {"event": "message", "data": json.dumps(data)}
            
            if task["status"] in ["completed", "failed"]:
                yield {"event": "done", "data": json.dumps(data)}
                break
            
            await asyncio.sleep(1)

    return EventSourceResponse(event_generator())

@app.get("/api/v1/fitness/generation-status/{task_id}/stream")
async def stream_fitness_status(task_id: str):
    async def event_generator():
        while True:
            if task_id not in tasks:
                yield {"event": "error", "data": json.dumps({"error": "Task not found"})}
                break
            
            task = tasks[task_id]
            data = {
                "status": task["status"],
                "progress": task["progress"],
                "message": task.get("error") if task["status"] == "failed" else "Processing",
                "result_id": task_id if task["status"] == "completed" else None
            }
            
            yield {"event": "message", "data": json.dumps(data)}
            
            if task["status"] in ["completed", "failed"]:
                yield {"event": "done", "data": json.dumps(data)}
                break
            
            await asyncio.sleep(1)

    return EventSourceResponse(event_generator())
