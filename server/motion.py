#
# motion.py
#
# Motion object trains model and predicts incoming motion data from websocket server in a separate thread
#

import sys
import asyncio
import signal
import time
import numpy as np

from connection import run_server
from state import MotionState
from util import logger
from threading import Thread, Lock

log = logger("motion")


class Motion:

    def __init__(self, motions, ip, model, training_duration=5.0):
        self.ip = ip
        self.port = 8765

        self.motions = motions
        self.frequency = 40.0
        self.training_duration = training_duration
        self.chunk_size = 5

        self.model = model
        self.classification_winow_size = 0
        self.measurements_window_size = 200

        self.state_event = None  # awaited in MAIN, triggered in CHILD
        self.prediction_event = None  # awaited in MAIN, triggered in CHILD
        self.stop_event = None  # awaited in CHILD, triggered in MAIN

        self.state = MotionState.AWAIT_CONNECTION
        self.state_lock = Lock()

        self.connection_lock = Lock()
        self.measurements_lock = Lock()
        self.predictions_lock = Lock()

        self.reset()

    def reset(self):
        # data state
        self.connection = None
        self.measurements_queue = []
        self.measurements_window = []
        self.predictions_queue = []

        # statistics
        self.prediction_time = 0
        self.training_time = None
        self.test_accuracy = None

    # send state event for main thread
    def set_state(self, new_state):
        with self.state_lock:
            log(f"update_state: {new_state}")
            self.state = new_state
            if self.state_event is not None:
                self.state_event.set()

    def get_state(self):
        with self.state_lock:
            return self.state

    def set_connection(self, host, port, time):
        with self.connection_lock:
            self.connection = host, port, time

    def get_connection(self):
        with self.connection_lock:
            return self.connection

    async def train_model(self, training_data):
        t = time.time()
        self.test_accuracy = self.model.fit(training_data)
        if self.test_accuracy is None:
            self.test_accuracy = -1
        self.training_time = time.time() - t
        self.classification_winow_size = self.model.min_input_length()

    async def process_measurements(self, new_measurements):
        to_predict = None
        with self.measurements_lock:
            self.measurements_queue += new_measurements
            self.measurements_window += new_measurements
            self.measurements_window = self.measurements_window[-self.measurements_window_size:]
            if len(self.measurements_window) >= self.classification_winow_size:
                to_predict = np.array(self.measurements_window[-self.classification_winow_size:])
        if to_predict is not None:
            t = time.time()
            prediction = self.model.predict_single(to_predict)
            pred_time = time.time() - t
            with self.predictions_lock:
                self.predictions_queue.append(prediction)
                self.prediction_time = pred_time

    def get_measurements(self):
        with self.measurements_lock:
            if len(self.measurements_queue) > 0:
                measurements = self.measurements_queue
                self.measurements_queue = []
                return np.array(measurements)
            else:
                return None

    def get_predictions(self):
        with self.predictions_lock:
            if len(self.predictions_queue) > 0:
                predictions = self.predictions_queue
                self.predictions_queue = []
                return np.array(predictions), self.prediction_time
            else:
                return None, self.prediction_time


    # trigger stop event for websocket server
    def stop(self):
        log("stop server")
        try:
            self.stop_event.set()
        except:
            pass


    # create thread for websocket server and processing data
    def create_thread(self):

        # threadsafe event, only awaitable where it was created
        class Event_ts(asyncio.Event):
            def set(self):
                self._loop.call_soon_threadsafe(super().set)

        # create awaitable events for main thread
        self.state_event = Event_ts() 
        self.prediction_event = Event_ts() 

        # run server in new thread
        def f():
            log("started motion thread")
            asyncio.set_event_loop(asyncio.new_event_loop())
            self.stop_event = Event_ts() # awaitable in new thread, set event from main thread
            asyncio.get_event_loop().run_until_complete(run_server(self,))
            asyncio.get_event_loop().run_forever()

        # attach termination of new thread to main thread
        def sigint_handler(sig, frame):
            log("sigint")
            self.stop()
            sys.exit(0)
        signal.signal(signal.SIGINT, sigint_handler)

        return Thread(target=f)




