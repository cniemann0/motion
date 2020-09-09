#
# overview.py
#
# visualize the reference data set
#

import matplotlib
import matplotlib.pyplot as plt
from recording import load_recording
from visualization import plot_measurements

dir = "data/reference/"
A = load_recording(dir + "A.json").measurements
B = load_recording(dir + "B.json").measurements
C = load_recording(dir + "C.json").measurements
Play = load_recording(dir + "Play.json").measurements
Chaotic = load_recording(dir + "Chaotic.json").measurements
Rest = load_recording(dir + "Rest.json").measurements

matplotlib.use("TkAgg")
#plot_measurements([A], titles=[""], frequency=40)
#plot_measurements([B], titles=[""], frequency=40)
#plot_measurements([C], titles=[""], frequency=40)
#plot_measurements([Play[80:80+400,:]], titles=[""], frequency=40)
plot_measurements([Chaotic[:200,:]/3], titles=[""], frequency=40)
plot_measurements([Rest[:200]], titles=[""], frequency=40)
plt.show(block=True)