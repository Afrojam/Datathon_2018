"""
Description:

Owner : Manuel Sarmiento
Creation Date : 20/01/18
Last Contributor : 
Last Modification : 
"""


import numpy as np
import os
from keras.layers import (Dense, Dropout)
from keras.models import Sequential
from keras.optimizers import Adam
from keras.callbacks import ModelCheckpoint, TensorBoard, EarlyStopping, ReduceLROnPlateau
from keras import regularizers
import pandas as pd
num_models = 2


def train():
    days = pd.date_range('2014-01-01 00:00:00', '2014-12-31 23:00:00', freq='1D')
    xgb_data = pd.read_csv('00_Dataset/xgb_2014.csv', sep=';')
    rf_data = pd.read_csv('00_Dataset/RF_prob_2014.csv', sep=';')
    lg_data = pd.read_csv('00_Dataset/lg_2014.csv', sep=',')
    xgb_data = xgb_data.sort_values(by=['id_station', 'fecha'])
    rf_data = rf_data.sort_values(by=['id_station', 'date'])
    lg_data = lg_data.sort_values(by=['id_station', 'fecha'])
    obs = pd.read_csv('00_Dataset/obs_daily.csv',sep=';')
    obs = obs[['fecha', 'id_station', 'col_count']]
    obs.col_count = (obs.col_count > 0).astype(np.int)
    obs = obs[(obs.fecha >= '2014-01-01') & (obs.fecha <= '2014-12-31 23:00:00')]
    obs = obs.sort_values(by=['id_station', 'fecha'])

    x = np.zeros(shape=(363, 24 * 7 * num_models))
    x_val = np.zeros(shape=(31, 24 * 7 * num_models))
    y = np.zeros(shape=(363, 7))
    y_val = np.zeros(shape=(31, 7))

    i = 0
    for day in days:
        xgb_day = xgb_data[(xgb_data['fecha'] >= str(day)) & (xgb_data['fecha'] < str(day + 1))].prob_NO2.values
        if xgb_day.shape[0] != 24 * 7:
            continue
        rf_day = rf_data[(rf_data['date'] >= str(day)) & (rf_data['date'] < str(day + 1))].prob_NO2.values
        lg_day = lg_data[(lg_data['fecha'] >= str(day)) & (lg_data['fecha'] < str(day + 1))].prob.values

        #x[i] = np.r_[xgb_day, rf_day, lg_day]
        x[i] = np.r_[xgb_day, lg_day]
        y_day = obs[(obs['fecha'] >= str(day.date())) & (obs['fecha'] < str((day+1).date()))].col_count.values
        y[i] = y_day
        i += 1
    i = 0
    for day in days[334:]:
        xgb_day = xgb_data[(xgb_data['fecha'] >= str(day)) & (xgb_data['fecha'] < str(day + 1))].prob_NO2.values
        rf_day = rf_data[(rf_data['date'] >= str(day)) & (rf_data['date'] < str(day + 1))].prob_NO2.values
        lg_day = lg_data[(lg_data['fecha'] >= str(day)) & (lg_data['fecha'] < str(day + 1))].prob.values
        #x_val[i] = np.r_[xgb_day, rf_day, lg_day]
        x_val[i] = np.r_[xgb_day, lg_day]

        y_day = obs[(obs['fecha'] >= str(day.date())) & (obs['fecha'] < str((day+1).date()))].col_count.values
        y_val[i] = y_day
        i += 1

    path_log = 'logs'
    path_checkpoint = 'final_model_probs.hdf5'
    tb_callback = TensorBoard(log_dir=path_log)
    save_model = ModelCheckpoint(filepath=path_checkpoint,
                                 monitor='val_loss',
                                 verbose=0,
                                 save_best_only=True,
                                 save_weights_only=True,
                                 mode='auto',
                                 period=1)
    early_stopping = EarlyStopping(monitor='val_loss', patience=20)
    reduce_lr = ReduceLROnPlateau(monitor='val_loss', factor=0.9,
                                  patience=1, min_lr=1e-9)

    lr = 0.001
    model = Sequential()
    model.add(Dense(24*7, input_shape=(24 * 7 * num_models,), name='fc1', trainable=True, activation='sigmoid'))
    model.add(Dropout(0.2))
    model.add(Dense(35, name='fc2', trainable=True, activation='sigmoid'))
    model.add(Dense(7, name='fc3', trainable=True, activation='sigmoid'))

    adam = Adam(lr=lr)
    model.compile(loss='binary_crossentropy', optimizer=adam, metrics=['binary_crossentropy'])  # metrics?

    model.fit(x,
              y,
              batch_size=30,
              #validation_data=(x_val, y_val),
              verbose=1,
              epochs=50,
              shuffle=1,
              callbacks=[tb_callback, save_model, early_stopping, reduce_lr])


import datetime

num_models = 2

def predict():
    model = Sequential()
    model.add(Dense(24*7, input_shape=(24 * 7 * num_models,), name='fc1', trainable=True, activation='sigmoid'))
    model.add(Dropout(0.9))
    model.add(Dense(90, name='fc2', trainable=True, activation='sigmoid'))
    model.add(Dense(7, name='fc3', trainable=True, activation='sigmoid'))
    model.load_weights('final_model_probs.hdf5')
    xgb_data = pd.read_csv('00_Dataset/xgb_2015.csv', sep = ';')
    mask = xgb_data.prob_NO2 < 0
    xgb_data.loc[mask, 'prob_NO2'] = 0
    rf_data = pd.read_csv('00_Dataset/RF_prob_2015.csv', sep=';')
    lm_data = pd.read_csv('00_Dataset/lg_2015.csv', sep=',')
    xgb_data = xgb_data.sort_values(by=['id_station', 'date'])
    rf_data = rf_data.sort_values(by=['id_station', 'date'])
    lm_data = lm_data.sort_values(by=['id_station', 'fecha'])

    days = pd.date_range('2015-01-03 00:00:00', '2015-12-31 23:00:00', freq='3D')

    x_pred = np.zeros(shape=(121, 24 * 7 * num_models))
    i = 0
    for day in days:
        xgb_day = xgb_data[(xgb_data['date'] >= str(day)) & (xgb_data['date'] < str(day + datetime.timedelta(days=1)))].prob_NO2.values
        rf_day = rf_data[(rf_data['date'] >= str(day)) & (rf_data['date'] < str(day + datetime.timedelta(days=1)))].prob_NO2.values
        lm_day = lm_data[(lm_data['fecha'] >= str(day)) & (lm_data['fecha'] < str(day + datetime.timedelta(days=1)))].prob.values
        #x_pred[i] = np.r_[xgb_day, rf_day, lm_day]
        x_pred[i] = np.r_[xgb_day, lm_day]
        i += 1

    prediction = model.predict(x_pred)
    results = []
    for p in prediction:
        for i in p:
            results.append(i)
    with open('results_join_5.txt', 'w') as f:
        for item in results:
            f.write("%s\n" % item)
