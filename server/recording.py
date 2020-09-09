#
# recording.py
#
# load recordings from json files into an object
#


import os
import json
import numpy as np

from datetime import datetime


def smooth_measurements(measurements):
    measurements = np.array(measurements)
    x = np.array([np.convolve(measurements[:, i], [1/5, 1/5, 1/5, 1/5, 1/5, 0, 0, 0, 0], mode="same") for i in range(measurements.shape[1])]).T
    return x

class Recording:

    def __init__(self, timestamp, label, description, frequency, duration, interval_variance, exact_duration, measurements, smooth=True):
        self.timestamp = timestamp
        self.label = label
        self.description = description
        self.frequency = frequency 
        self.duration = duration
        self.interval_variance = interval_variance
        self.exact_duration = exact_duration
        self.measurements = smooth_measurements(measurements) if smooth else np.array(measurements)


def load_recording(path, smooth=True):

    try: 
        with open(path, "r") as f:
            try: 
                content = json.loads(f.read())

                timestamp = datetime.strptime(content["timestamp"], "%Y-%m-%d_%H:%M:%S")
                label = content["name"]
                description = content["description"]
                frequency = float(content["frequency"]) # in ios als float speichern!
                duration = float(content["duration"])
                interval_variance = float(content["intervalVariance"])
                exact_duration = float(content["exactDuration"])
                mes = content["measurements"]
                measurements = [mes[i]["acceleration"] + mes[i]["rotation"] for i in range(len(mes))]

                return Recording(timestamp, label, description, frequency, duration, interval_variance, exact_duration, measurements, smooth=smooth)
            except:
                print("failed parsing file:", path)
    except:
        print("file does not exist:", path)


def load_all_recordings(directory, frequency=None, labels=None, smooth=True):
    recordings = []
    for filename in os.listdir(directory):
        path = os.path.join(directory, filename)
        if os.path.isfile(path):
            recording = load_recording(path, smooth=smooth)
            if recording is not None:
                recordings.append(recording)
    
    if frequency != None:
        recordings = [r for r in recordings if r.frequency == frequency]
    if labels != None:
        recordings = [r for r in recordings if r.label in labels]

    return recordings