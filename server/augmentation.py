#
# augmentation.py
#
# generate augmented training records (rotation and time scaling)
#

from math import sqrt, cos, sin, radians, ceil, floor
import numpy as np


# https://stackoverflow.com/questions/6802577/rotation-of-3d-vector
def rotation_matrix(axis, theta):
    """
    Return the rotation matrix associated with counterclockwise rotation about
    the given axis by theta radians.
    """
    axis = np.asarray(axis)
    axis = axis / sqrt(np.dot(axis, axis))
    a = cos(theta / 2.0)
    b, c, d = -axis * sin(theta / 2.0)
    aa, bb, cc, dd = a * a, b * b, c * c, d * d
    bc, ad, ac, ab, bd, cd = b * c, a * d, a * c, a * b, b * d, c * d
    return np.array([[aa + bb - cc - dd, 2 * (bc + ad), 2 * (bd - ac)],
                     [2 * (bc - ad), aa + cc - bb - dd, 2 * (cd + ab)],
                     [2 * (bd + ac), 2 * (cd - ab), aa + dd - bb - cc]])


def rotate_axis(measurements, axis, angle):
    if angle == 0:
        return measurements
    rot_axis = np.array([0,0,0])
    rot_axis[axis] = 1
    rot_matrix = rotation_matrix(rot_axis, angle)
    return np.dot(rot_matrix, measurements.T).T


def augment_rotation(multiple_measurements, delta_angle, n_angles):
    augmented_measurements = []

    for axis in range(3):
        for i in range(-n_angles, n_angles + 1):
            angle = delta_angle * i
            for measurements in multiple_measurements:
                augmented = rotate_axis(measurements, axis, radians(angle))
                augmented_measurements.append(augmented)

    return augmented_measurements


def scale_time(measurements, time_percent):
    old_length = measurements.shape[0]
    new_length = int(old_length * time_percent)
    scaled_measurements = np.zeros((new_length, 3))
    ratio = (old_length - 1)/(new_length - 1)
    scaled_measurements[0] = measurements[0]
    scaled_measurements[-1] = measurements[-1]
    for new_i in range(1, new_length - 1):
        old_i = round(new_i*ratio,4)
        lp = old_i % 1
        scaled_measurements[new_i] = (1 - lp)*measurements[floor(old_i)] + lp * measurements[ceil(old_i)]
    return scaled_measurements


def augment_timescale(multiple_measurements, delta_time, n_times):
    augmented_measurements = []
    for i in range(-n_times, n_times + 1):
        time_percent = 1 + delta_time * i
        for measurements in multiple_measurements:
            augmented = scale_time(measurements, time_percent)
            augmented_measurements.append(augmented)

    return augmented_measurements


def default_augmentation(multiple_measurements):
    augmented_measurements = multiple_measurements
    augmented_measurements = augment_rotation(augmented_measurements, 10, 2)
    augmented_measurements = augment_timescale(augmented_measurements, 0.1, 3)
    return augmented_measurements

