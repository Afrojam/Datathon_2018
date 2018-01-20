"""
Description:

Owner : Manuel Sarmiento
Creation Date : 20/01/18
Last Contributor : 
Last Modification : 
"""

import os
import pandas as pd
import numpy as np
import pickle
# data = pd.read_csv('/home/manuel/Documents/Projects/Datathon_2018/00_Dataset/dataset.csv', sep=';')
data = pd.read_csv('/ssd/home/manuel/airquality/data/dataset.csv', sep=';')

x = []
x_fc_t = []
x_fc_y = []
y = []
y_hour_prob = []
y_day_prob = []
stations = np.unique(data['id_station'])
days = pd.date_range('2013-01-09 00:00:00', '2014-12-31 00:00:00', freq='1H')
data = data.sort_values(by=['date', 'id_station'])
data['exceed'] = data.no2_2
data['exceed'] = (data['exceed'] > 100).astype(np.int)


def prepare_data(data, t_interval=8, num_stations=7):
    for day in days:
        print day
        x_day = []
        x_fc_day = []
        x_fc_yest = []
        y_day = []
        y_hour = []
        # for sta in stations:
        #     data_sta = data[data['id_station'] == sta]
        data_x = data[(data['date'] < str(day)) & (data['date'] >= str(day - t_interval))]
        data_y = data[(data['date'] >= str(day)) & (data['date'] < str(day + 1))]
        if data_x.shape[0] != (t_interval * num_stations) or data_y.shape[0] != (num_stations):
            print 'not enough data points'
            continue
        #x_day.append(data_x['no2'].values)
        #x_fc_day.append(data_x['FC_T_2'].values)
        #x_fc_yest.append(data_x['FC_Y_2'].values)
        #y_day.append(data_y['no2'].values)
        y_day = (data_y.groupby('id_station')['exceed'].sum() >0).astype(np.int)
        x.append(data_x['no2_2'].values)
        x_fc_t.append(data_x['FC_T_2'].values)
        x_fc_y.append(data_x['FC_Y_2'].values)
        y.append(data_y['no2_2'].values)
        y_hour_prob.append(data_y['exceed'].values)
        y_day_prob.append(y_day.values)

prepare_data(data)

with open('x.pkl','w') as f:
    pickle.dump(x, f)
with open('x_t2.pkl','w') as f:
    pickle.dump(x_fc_t, f)
with open('x_y2.pkl','w') as f:
    pickle.dump(x_fc_y, f)
with open('y.pkl','w') as f:
    pickle.dump(y, f)
with open('y_hour.pkl','w') as f:
    pickle.dump(y_hour_prob, f)
with open('y_day.pkl','w') as f:
    pickle.dump(y_day_prob, f)

x_train = x[:int(len(x)*0.8)]
x_val = x[int(len(x)*0.8):]

x_fc_t_train = x_fc_t[:int(len(x_fc_t)*0.8)]
x_fc_t_val = x_fc_t[int(len(x_fc_t)*0.8):]

x_fc_y_train = x_fc_y[:int(len(x_fc_y)*0.8)]
x_fc_y_val = x_fc_y[int(len(x_fc_y)*0.8):]

y_train = y[:int(len(y)*0.8)]
y_val = y[int(len(y)*0.8):]

y_hour_prob_train = y_hour_prob[:int(len(y_hour_prob)*0.8)]
y_hour_prob_val = y_hour_prob[int(len(y_hour_prob)*0.8):]

y_day_prob_train = y_day_prob[:int(len(y_day_prob)*0.8)]
y_day_prob_val = y_day_prob[int(len(y_day_prob)*0.8):]




import h5py

f_dataset = h5py.File('data/dataset_py.hdf5', 'w')
f_dataset_subset = f_dataset.create_group('training')
f_dataset_subset_val = f_dataset.create_group('validation')
f_dataset_subset.create_dataset(
            'input',
            data=x_train,
            chunks=True,
            dtype='float32')
f_dataset_subset.create_dataset(
            'x_fc_t',
            data=x_fc_t_train,
            chunks=True,
            dtype='float32')
f_dataset_subset.create_dataset(
            'x_fc_y',
            data=x_fc_y_train,
            chunks=True,
            dtype='float32')
f_dataset_subset.create_dataset(
            'output',
            data=y_train,
            chunks=True,
            dtype='float32')
f_dataset_subset.create_dataset(
            'output_prob',
            data=y_hour_prob_train,
            chunks=True,
            dtype='float32')
f_dataset_subset.create_dataset(
            'output_prob_day',
            data=y_day_prob_train,
            chunks=True,
            dtype='float32')

f_dataset_subset_val.create_dataset(
            'input',
            data=x_val,
            chunks=True,
            dtype='float32')
f_dataset_subset_val.create_dataset(
            'x_fc_t',
            data=x_fc_t_val,
            chunks=True,
            dtype='float32')
f_dataset_subset_val.create_dataset(
            'x_fc_y',
            data=x_fc_y_val,
            chunks=True,
            dtype='float32')
f_dataset_subset_val.create_dataset(
            'output',
            data=y_val,
            chunks=True,
            dtype='float32')
f_dataset_subset_val.create_dataset(
            'output_prob',
            data=y_hour_prob_val,
            chunks=True,
            dtype='float32')
f_dataset_subset_val.create_dataset(
            'output_prob_day',
            data=y_day_prob_val,
            chunks=True,
            dtype='float32')

f_dataset.close()

print len(x)
print len(y)