#
# extraction.py
#
# feature extraction for motion data
#

import numpy as np

from recording import load_all_recordings
from sklearn.model_selection import train_test_split
from util import normalize_ts


def cut_windows(measurements, window_size, flat=False):
    X = []
    for i in range(len(measurements) - window_size + 1):
        sample = measurements[i: i + window_size, :]
        sample = normalize_ts(sample)
        if flat:
            sample = sample.flatten()
        X.append(sample)
    return np.array(X)


class Extractor:

    def __init__(self, window_size, step_size, features, ignore_rot=False):
        self.window_size = window_size 
        self.step_size = step_size
        self.features = features
        self.feature_function_dict = { "statistics" : (self.statistical_features, 30), "norm_few" : (self.norm_few_features, 3) }
        self.ignore_rot = ignore_rot

    def generate_data_from_recordings(self, path, files, files_train=[], frequency=50, test_size=0.5):

        grouped_recordings = [load_all_recordings(path, frequency=frequency, labels=group) for group in files]
        X, Y = [], []
        for c, recordings in enumerate(grouped_recordings):
            X_c = []
            for recording in recordings:
                X_c += self.generate(recording.measurements)
            X_c = np.array(X_c)
            Y_c = np.full((X_c.shape[0]), c)
            X.append(X_c)
            Y.append(Y_c)

        X = np.vstack(X)
        Y = np.hstack(Y).reshape((X.shape[0],))

        if len(files_train) == len(files):
            X_train, _, Y_train, _ = self.generate_data_from_recordings(path, files_train, test_size=0)
            return X_train, X, Y_train, Y
        elif test_size == 0:
            return X, None , Y, None
        else: 
            return train_test_split(X, Y, test_size=test_size, shuffle=True)


    def generate_data(self, label_measurements, test_size=0, max_samples_cls=None):
        X = []
        Y = []
        for i, (label, measurements) in enumerate(label_measurements):
            Xi = []
            Yi = []
            for m in measurements:
                X_label = self.generate(m)
                Xi += X_label
                Yi += [i for _ in range(len(X_label))]#np.full((len(X_label),1), i)
            Xi = np.vstack(Xi)
            if max_samples_cls is not None and max_samples_cls < Xi.shape[0]:
                np.random.shuffle(Xi)
                Xi = Xi[:max_samples_cls]
            X.append(Xi)
            Y.append(np.full((Xi.shape[0],1), i))

        X = np.vstack(X)
        Y = np.vstack(Y)

        if test_size == 0:
            # used to shuffle data
            X1, X2, Y1, Y2 = train_test_split(X, Y, test_size=0.5, shuffle=True)
            return np.vstack([X1, X2]), [], np.vstack([Y1, Y2]), []
        else:
            return train_test_split(X, Y, test_size=test_size, shuffle=True)


    def generate(self, measurements, step_1=False):
        measurements = np.asarray(measurements)
        m, n = measurements.shape

        step = 1 if step_1 else self.step_size

        X = []
        start = 0
        while start <= m - self.window_size:
            end = start + self.window_size
            points = measurements[start:end]
            X.append(self.extract_features(points))
            start += step

        return X


    def extract_features(self, points):
        points = points[-self.window_size:] # make sure to only use points from specified window
        x = []
        if self.features is None or len(self.features) == 0:
            return points.flatten()
        else:
            x = []
            for feature_function in [self.feature_function_dict[f_name][0] for f_name in self.features]:
                x.append(feature_function(points))
        return np.array(x).flatten()


    def statistical_features(self, x):
        if self.ignore_rot:
            x = x[:, :3]

        l = []
        # min, max, mean, median, std along each dimension
        l.append(np.min(x, axis=0))
        l.append(np.max(x, axis=0))
        l.append(np.mean(x, axis=0))
        l.append(np.median(x, axis=0))
        l.append(np.std(x, axis=0))

        return np.array(l).flatten()

    def norm_few_features(self, t):
        t = t[:, :3]
        t = normalize_ts(t)

        frequency = 40
        grad = np.gradient(t, axis=0) * frequency
        mult1 = np.mean(t[:,0] * grad[:,1])
        mult2 = np.mean(t[:, 0] * grad[:, 2])
        mult3 = np.mean(t[:, 1] * grad[:, 2])

        l = [mult1, mult2, mult3]

        #number of sign changes,

        return np.array(l)

    def get_sample_dim(self):
        return sum([self.feature_function_dict[feature][1] for feature in self.features])