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
    lr = 0.001
    model = Sequential()
    model.add(Dense(Dense(24, input_shape=(24 * num_models,), name='fc1', trainable=True, activation='sigmoid')))
    model.add(Dense(1, name='fc3', trainable=True, activation='sigmoid'))

    adam = Adam(lr=lr)
    model.compile(loss='mse', optimizer=adam, metrics=['mse'])  # metrics?

    # TODO load data
    xgb_data = pd.read_csv('data/xgb_2014.csv')
    rf_data = pd.read_csv('data/rf_2014.csv')
    lm_data = pd.read_csv('data/lm_2014.csv')

    obs = pd.read_csv('data/daily_obs.csv')

    x = []
    y = []
    x_val = []
    y_val = []

    path_log = 'logs'
    path_checkpoint = 'final_model.hdf5'
    tb_callback = TensorBoard(log_dir=path_log)
    save_model = ModelCheckpoint(filepath=path_checkpoint,
                                 monitor='val_loss',
                                 verbose=0,
                                 save_best_only=True,
                                 save_weights_only=True,
                                 mode='auto',
                                 period=1)
    early_stopping = EarlyStopping(monitor='val_loss', patience=3)

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
    model.add(Dense(Dense(24, input_shape=(24 * num_models,), name='fc1', trainable=True, activation='sigmoid')))
    model.add(Dense(12, name='fc2', trainable=True, activation='sigmoid'))
    model.add(Dense(1, name='fc3', trainable=True, activation='sigmoid'))
    model.load_weights('model_weights.hdf5')
    # TODO load data, xgboost, rf, lm
    xgb_data = pd.read_csv('xgb_' + str(day)[:10])
    rf_data = pd.read_csv('rf_' + str(day)[:10])
    lm_data = pd.read_csv('lm_' + str(day)[:10])
    
    x = []

    return model.predict(x)
