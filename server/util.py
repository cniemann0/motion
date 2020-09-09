#
# util.py
#
# useful helpers
#

import threading
import numpy as np


def logger(name):
    name_padded = f"[{name}]".ljust(13)
    
    def log(content):
        thread_padded = f"({threading.get_ident()})".ljust(8)
        print(thread_padded, name_padded, content)
    
    return log


def flatten(l):
    return [x for sublist in l for x in sublist]


def estimate_period(measurements, period_range=(15, 60)):
    size_cost = []
    min_window, max_window = period_range
    for ws in range(min_window, max_window + 1):
        windows = [measurements[i*ws:(i+1)*ws] for i in range(int(measurements.shape[0]/ws))]
        std = np.std(windows, axis=0)
        cost = (np.sum(std) / std.size) / len(windows)
        bias = 1 + 0.5*((ws - min_window) / (max_window - min_window)) #larger window sizes are punished
        cost = cost*bias
        size_cost.append((ws, cost))

    ws, cost = min(size_cost, key=lambda p: p[1])
    return ws


def normalize_ts(t):
    N = t.shape[0]
    e = sum(np.linalg.norm(t[i]) for i in range(N))
    normalized = (t / e) * N
    return normalized


def count_confusion(cm, cls):
    TP = cm[cls, cls]
    FP = np.sum(cm[:,cls]) - TP
    N = np.sum(cm) - np.sum(cm[cls,:])
    TN = N - np.sum(cm[:,cls]) + TP
    FN = np.sum(cm[cls,:]) - TP
    return TP, FP, TN, FN


def precision(cm, cls):
    TP, FP, TN, FN = count_confusion(cm, cls)
    return TP/(TP + FP)


def TPR(cm, cls):
    TP, FP, TN, FN = count_confusion(cm, cls)
    return TP/(TP + FN)


def FPR(cm, cls):
    TP, FP, TN, FN = count_confusion(cm, cls)
    return FP/(TN + FP)


def F1(cm, cls):
    TP, FP, TN, FN = count_confusion(cm, cls)
    return 2*TP/(2*TP + FP + FN)