from tkinter import *
import numpy as np

import sys
from classification import TsNN
from state import MotionState
from motion import Motion
from augmentation import default_augmentation


class RealtimeGraph:

    def __init__(self, frame, axes, frequency, time_window, y_range=(-1, 1), y_label="", title="", border_inset=50, colors=("red", "green", "blue"), black_axis=None):
        self.frame = frame
        self.axes = axes
        self.frequency = frequency
        self.time_window = time_window
        self.y_range = y_range
        self.y_label = y_label
        self.title = title
        self.border_inset = border_inset
        self.colors = colors
        self.black_axis = black_axis
        self.init_canvas()

        self.data = np.zeros((0,len(axes)))
        self.max_points = int(frequency * time_window)
        self.offset = 0
        self.xs = np.linspace(0, self.canvas_width, self.max_points + 1)[1:]

    def init_canvas(self):
        self.canvas = Canvas(self.frame, highlightthickness=0)
        width, height = self.frame.winfo_width() - 2*self.border_inset, self.frame.winfo_height() - 2*self.border_inset
        self.canvas_width, self.canvas_height = width, height
        title_label = Label(self.frame, text=self.title, font=("Helvetica", 14))
        title_label.place(x=self.border_inset, y=self.border_inset-25, width=width, height=25)
        self.canvas.place(x=self.border_inset, y=self.border_inset, width=width, height=height)

        # y-axis and y-labels
        min_y, max_y = self.y_range
        lw = 1
        for k in range(int(min_y), int(max_y) + 1):
            p = (k-min_y)/(max_y-min_y)
            x0 = 0 if k == 0 else width - 10
            y = (1-p)*(height - lw)
            self.canvas.create_line(x0, y, width, y, fill="black", width=lw)
            label = Label(self.frame, text=str(k), anchor=E, font=("Helvetica", 12))
            label.place(x=self.border_inset+width, y=self.border_inset + y-15, height=30, width=25)
        self.canvas.create_line(width - 1, 0, width - 1, height, fill="black", width=lw)

        # x-labels
        for k in range(1, int(self.time_window) + 1):
            p = k/self.time_window
            x = (1-p)*width
            label = Label(self.frame, text=f"-{k}s", font=("Helvetica", 11))
            label.place(x=self.border_inset + x - 20, y=self.border_inset + height, width=40)

    def reset(self):
        self.clear()
        self.data = np.zeros((0,len(self.axes)))
        self.offset = 0

    def clear(self):
        self.canvas.delete("line")

    def draw(self):
        self.clear()
        if self.data.shape[0] <= 1:
            return
        if self.offset == 0:
            x_coords = self.xs[-self.data.shape[0]:]
        else:
            x_coords = self.xs[- self.data.shape[0] - self.offset:-self.offset]
        for ax in range(len(self.axes)):
            ax_data = self.data[:, ax]
            if ax_data.shape[0] >= 150:
                pass
            line_data = [[x_coords[i], ax_data[i]] for i in range(ax_data.shape[0])]
            color = "black" if ax == self.black_axis else self.colors[ax % len(self.colors)]
            self.canvas.create_line(line_data, fill=color, tags="line", width=3)

    def shift(self, timesteps):
        self.offset += timesteps
        if self.offset >= self.max_points:
            self.data = np.zeros((0,len(self.axes)))
        else:
            self.data = self.data[- (self.max_points - self.offset):]

    def add_points(self, new_points):
        coords = self.calc_coords(new_points)
        self.data = np.vstack([self.data, coords])
        self.offset -= new_points.shape[0]

    def calc_coords(self, points):
        min_y, max_y = self.y_range
        coords = np.empty(points.shape)
        for i in range(points.shape[0]):
            for k in range(points.shape[1]):
                y = (1 - (points[i,k] - min_y) / (max_y - min_y)) * self.canvas_height
                coords[i,k] = min(self.canvas_height, max(0, y))
        return coords

    def update(self, new_points):
        self.shift(new_points.shape[0])
        self.add_points(new_points)
        self.draw()


class RealtimeViewer:

    def __init__(self, motion):
        self.motion = motion
        self.init_ui()
        self.reset_info()

        self.state = None
        
        self.mes_graph = RealtimeGraph(self.measurements_frame, ["ax1", "ax2", "ax3"], motion.frequency, 3, y_range=(-2, 2), y_label="m/s^2", title="Motion Data")
        self.pred_graph = RealtimeGraph(self.prediction_frame, motion.motions + ["other"], motion.frequency / motion.chunk_size, 3, y_range=(0, 1), y_label="Metric", title="Prediction", black_axis=len(motion.motions))
    
    def init_ui(self):
        self.root = Tk()
        plot_width = 800
        plot_height = 400
        status_height = 35
        info_width = 400
        frame_width = plot_width + info_width
        frame_height = 2*plot_height + status_height
        main_frame = Frame(self.root, width=frame_width, height=frame_height)
        main_frame.pack()

        self.measurements_frame = Frame(main_frame)
        self.measurements_frame.place(x=0, y=0, width=plot_width, height=plot_height)
        self.prediction_frame = Frame(main_frame)
        self.prediction_frame.place(x=0, y=plot_height, width=plot_width, height=plot_height)
        
        self.info_frame = Frame(main_frame)
        self.info_frame.place(x=plot_width, y=0, width=info_width, height=plot_height)

        label_height = 24
        right_inset = 10
        top_inset = 30
        self.status_label = Label(self.info_frame, font=("Helvetica", 13, "bold"), anchor=E)
        self.status_label.place(x=0, y=top_inset, width=info_width - right_inset, height=label_height)
        Label(self.info_frame, text="Status:", font=("Helvetica", 13, "bold"), anchor=W).place(x=0, y=top_inset)

        font = ("Helvetica", 12)
        self.motions_label = Label(self.info_frame, font=font, anchor=E, text=", ".join(self.motion.motions))
        self.frequency_label = Label(self.info_frame, font=font, anchor=E, text=f"{self.motion.frequency}Hz")
        self.chunk_label = Label(self.info_frame, font=font, anchor=E, text=str(self.motion.chunk_size))
        self.training_duration_label = Label(self.info_frame, font=font, anchor=E, text=f"{self.motion.training_duration}s")
        self.training_time_label = Label(self.info_frame, font=font, anchor=E)
        self.accuracy_label = Label(self.info_frame, font=font, anchor=E)
        self.classification_time = Label(self.info_frame, font=font, anchor=E)

        y = top_inset + 2*label_height
        spec = [
            ("Configuration", [(self.motions_label, "Motions"), (self.training_duration_label, "Training duration"), (self.frequency_label, "Frequency"), (self.chunk_label, "Chunk size")]),
            ("Training", [(self.training_time_label, "Training time"), (self.accuracy_label, "Test accuracy")]),
            ("Classification", [(self.classification_time, "Classification time")])
        ]
        for title, labels in spec:
            Label(self.info_frame, text=title, font=("Helvetica", 12, "bold"), anchor=W).place(x=0, y=y, width=info_width, height=label_height)
            y += label_height
            for label, name in labels:
                label.place(x=0, y=y, width=info_width - right_inset, height=label_height)
                Label(self.info_frame, text=name + ":", font=font, anchor=W).place(x=0, y=y, height=label_height)
                y += label_height
            y += label_height

        self.prediction_info_frame = Frame(main_frame)
        self.prediction_info_frame.place(x=plot_width, y=plot_height, width=info_width, height=plot_height)
        self.prediction_label = Label(self.prediction_info_frame, text="-", font=("Helvetica", 14))
        self.prediction_label.place(x=int(info_width/2), y=int(plot_height/2), anchor=CENTER)

        self.status_frame = Frame(main_frame)
        self.status_frame.place(x=0, y=2 * plot_height, width=frame_width, height=status_height)
        self.connection_label = Label(self.status_frame, text="...", font=("Helvetica", 12), background="gray90")
        self.connection_label.place(x=0, y=0, height=status_height, width=frame_width)

        self.root.update()

    def reset_info(self):
        self.status_label.configure(text="No Device Connected")
        self.training_time_label.configure(text="-")
        self.accuracy_label.configure(text="-")
        self.classification_time.configure(text="-")
        self.prediction_label.configure(text="-")

    def update_state_ui(self):
        if self.state == MotionState.AWAIT_CONNECTION:
            self.connection_label.configure(text=f"Running on {self.motion.ip}:{self.motion.port}", foreground="black")
            self.mes_graph.reset()
            self.pred_graph.reset()
            self.reset_info()
        elif self.state == MotionState.RECEIVE_TRAINING_DATA:
            connection = self.motion.get_connection()
            if connection is not None:
                host, port, time = connection
                self.connection_label.configure(text=f"Connected to {host}:{port}", foreground="green")
            self.status_label.configure(text="Waiting for Training Data")
        elif self.state == MotionState.TRAIN:
            self.status_label.configure(text="Training Model")
        elif self.state == MotionState.PREDICT:
            self.status_label.configure(text="Predicting")
            self.training_time_label.configure(text=f"{int(self.motion.training_time*1000)}ms")
            self.accuracy_label.configure(text="%.4f" % self.motion.test_accuracy)

    def loop(self):
        new_state = self.motion.get_state()
        if new_state != self.state:
            self.state = new_state
            self.update_state_ui()

        if self.state == MotionState.PREDICT:
            measurements = self.motion.get_measurements()
            if measurements is not None:
                self.mes_graph.update(measurements[:,:3])
            predictions, time = self.motion.get_predictions()
            if predictions is not None:
                self.pred_graph.update(predictions)
                clss = np.argmax(predictions)
                self.prediction_label.configure(text=(self.motion.motions + ["other"])[clss])
                self.classification_time.configure(text=f"{int(time*1000)}ms")

        self.root.after(1, self.loop)

    def run(self):
        motion_thread = self.motion.create_thread()
        motion_thread.start()
        self.root.after(100, self.loop)
        self.root.mainloop()
        self.motion.stop()


if __name__ == "__main__":
    if len(sys.argv) == 2:
        ip = sys.argv[1]
        motions = ["Forward", "Left", "Right"]
        model = TsNN(30, threshold=3.4, augmentation=None)
        RealtimeViewer(Motion(motions, ip, model, training_duration=5.0)).run()
    else:
        print("No ip-address specified.")