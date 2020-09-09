#
# classification.py
#
# classifiers and functions to predict
#

import time
import numpy as np
from sklearn.neighbors import NearestNeighbors

from extraction import cut_windows
from util import normalize_ts, flatten


# blueprint only
class Classifier:

    def fit(self, label_measurements) -> np.ndarray:
        raise NotImplementedError()

    def min_input_length(self) -> np.ndarray:
        raise NotImplementedError()

    def metric(self, x) -> np.ndarray:
        raise NotImplementedError()

    def predict_single(self, x) -> np.ndarray:
        raise NotImplementedError()


### KNN for time series ###

class TsNN:

    def __init__(self, window_size, threshold=np.inf, augmentation=None):
        self.threshold = threshold
        self.augmentation = augmentation
        self.labels = None
        self.nearest_neighbour = NearestNeighbors(n_neighbors=1, algorithm="kd_tree")#, metric=lambda a, b: fast.dist_flat(a, b, window_size))#, metric=dist)#, algorithm="ball_tree")
        self.X = None
        self.Y = None
        self.window_size = window_size

    def min_input_length(self):
        return self.window_size

    def fit_XY(self, X, Y):
        self.X = X
        self.Y = Y
        self.nearest_neighbour.fit(self.X)

    def fit(self, label_measurements):
        self.labels = [label for label, mes in label_measurements]
        Xs = []
        Ys = []
        for c, (_, multiple_measurements) in enumerate(label_measurements):
            multiple_measurements = [measurements[:,:3] for measurements in multiple_measurements]
            if self.augmentation is not None:
                multiple_measurements = self.augmentation(multiple_measurements)
            X_c = np.array(flatten(cut_windows(measurements, self.window_size, flat=True) for measurements in multiple_measurements))
            Xs.append(X_c)
            Ys.append(np.full((X_c.shape[0],), c))
        self.X = np.vstack(Xs)
        self.Y = np.hstack(Ys)
        t = time.time()
        self.nearest_neighbour.fit(self.X)
        print(f"training time: {((time.time() -t)*1000):.3f}ms")
        print(f"{self.X.shape[0]} training samples")

    def metric(self, x):
        x = x[:,:3]
        res = np.zeros((len(self.labels)+1,))
        if x.shape[0] < self.window_size:
            return res
        x = x[-self.window_size:]
        x = normalize_ts(x)

        x = x.flatten()
        dists, indices = self.nearest_neighbour.kneighbors(np.array([x]))
        min_index = indices[0][np.argmin(dists[0])]
        cls = self.Y[min_index]
        res[cls] = np.min(dists[0])

        return res

    def get_dists_classes(self, X):
        dists = []
        classes = []
        for i in range(X.shape[0]):
            x = X[i][-self.window_size:]
            x = x[:,:3]
            x = normalize_ts(x)
            x = x.flatten()
            distances, indices = self.nearest_neighbour.kneighbors(np.array([x]))
            dists.append(distances[0][0])
            classes.append(self.Y[indices[0][0]])
            #min_i, min_dist = fast.nearest_neighbour(x, self.X, self.window_size, 3)
            #dists.append(min_dist)
            #classes.append(self.Y[min_i])
        return dists, classes

    def predict_multiple(self, X):
        return np.array([self.predict_single(X[i]) for i in range(X.shape[0])])

    def predict_single(self, x):
        x = x[:, :3]
        pred = np.zeros((len(self.labels)+1,))
        if x.shape[0] < self.window_size:
            return pred
        x = x[-self.window_size:]
        x = normalize_ts(x)

        x = x.flatten()
        dists, indices = self.nearest_neighbour.kneighbors(np.array([x]))
        if np.min(dists) > self.threshold:
            pred[-1] = 1
        else:
            min_index = indices[0][np.argmin(dists[0])]
            cls = self.Y[min_index]
            pred[cls] = 1
        return pred


