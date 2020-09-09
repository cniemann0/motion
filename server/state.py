#
# status.py
#
# defines the status for the motion object communicating with the client 
#

from enum import Enum


class MotionState(Enum):
    AWAIT_CONNECTION = 0
    RECEIVE_TRAINING_DATA = 1
    TRAIN = 2
    PREDICT = 3
    