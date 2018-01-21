"""
Description:

Owner : Manuel Sarmiento
Creation Date : 20/01/18
Last Contributor : 
Last Modification : 
"""

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
from keras.callbacks import ModelCheckpoint, TensorBoard, EarlyStopping
from keras import regularizers
import pandas as pd
num_models = 3


def train():
    days = pd.date_range('2014-01-01 00:00:00', '2014-12-31 23:00:00', freq='1D')

    xgb_data = pd.read_csv('00_Dataset/xgbr_2014.csv', sep=';')
    # rf_data = pd.read_csv('00_Dataset/rfr_2014.csv', sep=';')
    lm_data = pd.read_csv('00_Dataset/lm_2014.csv', sep=',')
    cub_data = pd.read_csv('00_Dataset/cubist_2014.csv', sep=';')
    xgb_data = xgb_data.sort_values(by=['id_station', 'date'])
    # rf_data = rf_data.sort_values(by=['id_station', 'fecha'])
    lm_data = lm_data.sort_values(by=['id_station', 'fecha'])
    cub_data = cub_data.sort_values(by=['id_station', 'date'])
    obs = pd.read_csv('00_Dataset/obs_daily.csv', sep=';')
    obs = obs[['fecha', 'id_station', 'col_count']]
    obs.col_count = (obs.col_count > 0).astype(np.int)
    obs = obs[(obs.fecha >= '2014-01-01') & (obs.fecha <= '2014-12-31 23:00:00')]
    obs = obs.sort_values(by=['id_station', 'fecha'])

    x = np.zeros(shape=(332, 24 * 7 * num_models))
    x_val = np.zeros(shape=(31, 24 * 7 * num_models))
    y = np.zeros(shape=(332, 7))
    y_val = np.zeros(shape=(31, 7))

    i = 0
    for day in days[:334]:
        xgb_day = xgb_data[(xgb_data['date'] >= str(day)) & (xgb_data['date'] < str(day + 1))].NO2.values
        if xgb_day.shape[0] != 24 * 7:
            continue
        # rf_day = rf_data[(rf_data['fecha'] >= str(day)) & (rf_data['fecha'] < str(day + 1))].prob_NO2.values
        lm_day = lm_data[(lm_data['fecha'] >= str(day)) & (lm_data['fecha'] < str(day + 1))].pred_no2_2.values
        cub_day = cub_data[(cub_data['date'] >= str(day)) & (cub_data['date'] < str(day + 1))].prob_NO2.values
        # x[i] = np.r_[xgb_day, rf_day, lm_day, cub_day]
        x[i] = np.r_[xgb_day, lm_day, cub_day]
        y_day = obs[(obs['fecha'] >= str(day.date())) & (obs['fecha'] < str((day+1).date()))].col_count.values
        y[i] = y_day
        i+=1
    i = 0
    for day in days[334:]:
        xgb_day = xgb_data[(xgb_data['date'] >= str(day)) & (xgb_data['date'] < str(day + 1))].NO2.values
        # rf_day = rf_data[(rf_data['fecha'] >= str(day)) & (rf_data['fecha'] < str(day + 1))].prob_NO2.values
        lm_day = lm_data[(lm_data['fecha'] >= str(day)) & (lm_data['fecha'] < str(day + 1))].pred_no2_2.values
        cub_day = cub_data[(cub_data['date'] >= str(day)) & (cub_data['date'] < str(day + 1))].prob_NO2.values
        # x_val[i] = np.r_[xgb_day, rf_day, lm_day, cub_day]
        x_val[i] = np.r_[xgb_day, lm_day, cub_day]
        y_day = obs[(obs['fecha'] >= str(day.date())) & (obs['fecha'] < str((day+1).date()))].col_count.values
        y_val[i] = y_day
        i += 1

    path_log = 'logs'
    path_checkpoint = 'final_model_reg.hdf5'
    tb_callback = TensorBoard(log_dir=path_log)
    save_model = ModelCheckpoint(filepath=path_checkpoint,
                                 monitor='val_loss',
                                 verbose=0,
                                 save_best_only=True,
                                 save_weights_only=True,
                                 mode='auto',
                                 period=1)
    early_stopping = EarlyStopping(monitor='val_loss', patience=3)

    lr = 0.001
    model = Sequential()
    model.add(Dense(24 * 7, input_shape=(24 * 7 * num_models,), name='fc1', trainable=True, activation='sigmoid'))
    model.add(Dropout(0.2))
    model.add(Dense(35, name='fc2', trainable=True, activation='sigmoid'))
    model.add(Dense(7, name='fc3', trainable=True, activation='sigmoid'))

    adam = Adam(lr=lr)
    model.compile(loss='binary_crossentropy', optimizer=adam, metrics=['binary_crossentropy'])  # metrics?

    model.fit(x,
              y,
              batch_size=30,
              validation_data=(x_val, y_val),
              verbose=1,
              epochs=300,
              shuffle=1,
              callbacks=[tb_callback, save_model, early_stopping])


def predict(day):
    model = Sequential()
    model.add(Dense(Dense(24*7, input_shape=(24 * 7 * num_models,), name='fc1', trainable=True, activation='relu')))
    # model.add(Dense(12, name='fc2', trainable=True, activation='sigmoid'))
    model.add(Dense(7, name='fc3', trainable=True, activation='sigmoid'))
    model.load_weights('final_model_reg.hdf5')
    # TODO load data, xgboost, rf, lm
    xgb_data = pd.read_csv('xgb_' + str(day)[:10])
    rf_data = pd.read_csv('rf_' + str(day)[:10])
    lm_data = pd.read_csv('lm_' + str(day)[:10])
    cub_data = pd.read_csv('cub_' + str(day)[:10])

    xgb_data = xgb_data.sort_values(by=['id_station', 'fecha'])
    rf_data = rf_data.sort_values(by=['id_station', 'fecha'])
    lm_data = lm_data.sort_values(by=['id_station', 'fecha'])
    cub_data = cub_data.sort_values(by=['id_station', 'date'])

    x = []

    return model.predict(x)
