#
# connection.py
#
# responsible for websocket connection with client
#

import numpy as np
import sys
import websockets
import functools
import json
import asyncio

from state import MotionState
from util import logger
from datetime import datetime


log = logger("connection")

async def run_server(motion):
    log("server start")
    bound_handler = functools.partial(handle_connection, motion=motion)
    async with websockets.serve(bound_handler, motion.ip, motion.port, max_size=1048576) as server:
        motion.set_state(MotionState.AWAIT_CONNECTION)
        await motion.stop_event.wait()

    log("server stopped")
    sys.exit(0) # stop this thread when stop_task() was awaited


async def handle_connection(websocket, path, motion):
    host, port = websocket.remote_address
    log(f"connected: {host}:{port}")
    
    try:
        motion.set_connection(host, port, datetime.now())
        motion.set_state(MotionState.RECEIVE_TRAINING_DATA)

        # sending configuration to client
        config = {
            "motions": motion.motions,
            "frequency": motion.frequency,
            "trainingDuration": motion.training_duration,
            "chunkSize": motion.chunk_size
        }
        await websocket.send(json.dumps(config))


        # client sends training data for each class
        training_data = []
        for _ in motion.motions:
            payload = await websocket.recv()
            data_dict = json.loads(payload)
            motion_label = data_dict["motion"]
            motion_measurements = data_dict["measurements"]
            training_data.append((motion_label, [np.array(motion_measurements)]))


        # wait while training the model
        motion.set_state(MotionState.TRAIN)
        await motion.train_model(training_data)
        await websocket.send("ready") # inform client that the server is ready to predict a steady stream


        # receive measurements from client
        motion.set_state(MotionState.PREDICT)
        while(True):
            payload = await websocket.recv()
            measurements = json.loads(payload)
            asyncio.create_task(motion.process_measurements(measurements))
   
    except Exception as err:
        try:
            log(f"error in connection handler: {err.message}")
        except:
            log(f"error in connection handler: {err}")
    finally:
        log("connection closed")
        motion.set_state(MotionState.AWAIT_CONNECTION)
        motion.reset()


