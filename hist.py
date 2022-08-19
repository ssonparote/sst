#!/usr/bin/env python

from bokeh.models.annotations import BoxAnnotation, ColorBar, Label
from bokeh.models.axes import LinearAxis
from bokeh.models.mappers import LinearColorMapper
from bokeh.models.ranges import Range1d
from bokeh.models.tickers import FixedTicker
import msgpack
import numpy as np

from scipy.signal import savgol_filter

from bokeh.io import curdoc
from bokeh.io import output_file, save
from bokeh.layouts import column, layout
from bokeh.models import ColumnDataSource
from bokeh.palettes import Spectral9
from bokeh.plotting import figure


def group(array):
    idx_sort = np.argsort(array)
    sorted_records_array = array[idx_sort]
    _, idx_start = np.unique(sorted_records_array, return_index=True)
    res = np.split(idx_sort, idx_start[1:])
    return res

def hist_velocity(travel, max_travel):
    velocity = np.gradient(travel, 0.0002)
    
    step = 100
    mn = int(((velocity.min() // step) - 1) * step)
    mx = int(((velocity.max() // step) + 1) * step)
    bins = list(range(mn, mx, step))
    dig = np.digitize(velocity, bins=list(range(mn, mx, step))) - 1

    data = []
    idx_groups = group(dig)
    if (max_travel % 10 == 0):
        mx = max_travel
    else:
        mx = (max_travel // 10 + 1) * 10
    travel_bins = np.linspace(0, mx, 10)
    for g in idx_groups:
        t = travel[g]
        th, _ = np.histogram(t, bins=travel_bins)
        th = th / len(velocity) * 100
        data.append(th)

    data = np.transpose(np.array(data))

    data_dict = dict(y = bins[1:])
    xs = []
    for i in range(len(data)):
        xs.append(f'x{i}')
        data_dict[f'x{i}'] = data[i]

    return xs, travel_bins, ColumnDataSource(data=data_dict)

def velocity_histogram_figure(travel, max_travel, title):
    xs, tbins, source = hist_velocity(travel, max_travel)
    p = figure(
        title=title,
        height=500,
        x_axis_label="Time (%)",
        y_axis_label='Velocity (mm/s)',
        toolbar_location='above',
        tools='ypan,ywheel_zoom,reset',
        active_drag='ypan',
        active_scroll='ywheel_zoom',
        output_backend='webgl')
    p.x_range.start = 0
    p.y_range.flipped = True
    p.hbar_stack(xs, y='y', height=80, color=Spectral9, source=source)

    mapper = LinearColorMapper(palette=Spectral9[::-1], low=tbins[-1], high=0)
    color_bar = ColorBar(
        color_mapper=mapper,
        width=8,
        title="Travel (mm)",
        ticker=FixedTicker(ticks=tbins))
    p.add_layout(color_bar, 'right')

    lowspeed_box = BoxAnnotation(top=450, bottom=-450, left=0, fill_color='#FFFFFF', fill_alpha=0.1)
    p.add_layout(lowspeed_box)

    rebound = Label(x=70, y=70, x_units='screen', y_units='screen',
                 text='Collected by Luke C.\n2016-04-01', text_color="lightgray", render_mode='css',
                 border_line_color='gray', border_line_alpha=1.0,
                 background_fill_color='black', background_fill_alpha=0.8)
    p.add_layout(rebound)
    return p

def travel_histogram_figure(travel, max_travel, color, title):
    hist, bins = np.histogram(travel, bins=np.arange(0, max_travel+max_travel/20, max_travel/20))
    hist = hist / len(travel) * 100
    p = figure(
        title=title,
        height=250,
        sizing_mode="stretch_width",
        x_axis_label="Time (%)",
        y_axis_label='Travel (mm)',
        toolbar_location='above',
        tools='ypan,ywheel_zoom,reset',
        active_drag='ypan',
        active_scroll='ywheel_zoom',
        output_backend='webgl')
    p.x_range.start = 0
    p.y_range.flipped = True
    p.hbar(y=bins[:-1], height=5, left=0, right=hist, color=color)
    return p

def travel_figure(telemetry, front_color, rear_color):
    p_travel = figure(
        title="Suspension travel",
        height=400,
        sizing_mode="stretch_width",
        toolbar_location='above',
        tools='xpan,xwheel_zoom,xzoom_in,xzoom_out,reset',
        active_drag='xpan',
        active_scroll='xwheel_zoom',
        x_axis_label='Elapsed time (s)',
        y_axis_label='Travel (mm)',
        y_range=(telemetry['ForkCalibration']['MaxTravel'], 0),
        output_backend='webgl')
    p_travel.extra_y_ranges = {'rear': Range1d(start=telemetry['MaxWheelTravel'], end=0)}
    p_travel.add_layout(LinearAxis(y_range_name='rear'), 'right')
    p_travel.line(
        np.around(telemetry['Time'], 4)[::100],
        np.around(telemetry['FrontTravel'], 4)[::100],
        legend_label="Front travel",
        line_width=2,
        color=front_color)
    p_travel.line(
        np.around(telemetry['Time'], 4)[::100],
        np.around(telemetry['RearTravel'], 4)[::100],
        y_range_name='rear',
        legend_label="Rear travel",
        line_width=2,
        color=rear_color)
    return p_travel

# ------

telemetry = msgpack.unpackb(open('/home/sghctoma/projects/sst/sample_data/20220724/00097.PSST', 'rb').read())
rear_travel = savgol_filter(telemetry['RearTravel'], 51, 3)
rear_travel[rear_travel<0] = 0
front_travel = savgol_filter(telemetry['FrontTravel'], 51, 3)
front_travel[front_travel<0] = 0

front_max = telemetry['ForkCalibration']['MaxTravel']
rear_max = telemetry['MaxWheelTravel']

# ------

curdoc().theme = 'dark_minimal'
output_file("stacked_split.html")

front_color = Spectral9[0]
rear_color = Spectral9[1]

p_travel = travel_figure(telemetry, front_color, rear_color)
p_front_vel_hist = velocity_histogram_figure(front_travel, front_max, "Front velocity histogram")
p_rear_vel_hist = velocity_histogram_figure(rear_travel, rear_max, "Rear velocity histogram")
p_front_travel_hist = travel_histogram_figure(front_travel, front_max, front_color, "Front travel histogram")
p_rear_travel_hist = travel_histogram_figure(rear_travel, rear_max, rear_color, "Rear travel histogram")

l = layout(
    children=[
        [p_travel],
        [column(p_front_travel_hist, p_rear_travel_hist), p_front_vel_hist, p_rear_vel_hist],
    ],
    sizing_mode='stretch_width')
save(l)
