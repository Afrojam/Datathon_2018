"""
Description:

Owner : Manuel Sarmiento
Creation Date : 16/01/18
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
import h5py
import argparse

# n_layers = 300
# t_interval = 4
# lr_lr = 0.00001
# epochs = 3000
# batch_size = 300  # ??
# lambd = 0.01
# mu = 1e-5

# TO TEST:
# activations vs no activations(paper)
# batch_size
# freeze autoencoder vs small lr
#


def load_autoencoder(experiment_id, lr, epochs, batch_size, t_interval, lambd, mu, n_neurons, dropout, data_days=24):
    autoencoder = Sequential()
#    autoencoder.add(Dense(n_neurons, input_shape=(num_stations * t_interval,), name='fc1',
#                          trainable=True, activation='relu', kernel_regularizer=regularizers.l2(lambd),
#                          activity_regularizer=regularizers.l1(mu)))  # change activations?
#    # model2.add(Dropout(dropout, name='drop1'))
#    autoencoder.add(Dense(n_neurons, name='fc2', trainable=True, activation='relu',
#                          kernel_regularizer=regularizers.l2(lambd), activity_regularizer=regularizers.l1(mu)))  # change activations?
#    # model2.add(Dropout(dropout, name='drop2'))
#    autoencoder.add(Dense(n_neurons, name='fc3', trainable=True, activation='relu',
#                          kernel_regularizer=regularizers.l2(lambd), activity_regularizer=regularizers.l1(mu)))  # change activations? , activity_regularizer=regularizers.l1(mu)
#    # model2.add(Dropout(dropout, name='drop3'))
#    autoencoder.add(Dense(num_stations * t_interval, name='fc4', trainable=True, activation='relu',
#                          kernel_regularizer=regularizers.l2(lambd), activity_regularizer=regularizers.l1(mu)))
    autoencoder.add(Dense(n_neurons, input_shape=(num_stations * t_interval,), name='fc1',
                          trainable=True, activation='relu', kernel_regularizer=regularizers.l2(lambd),
                          activity_regularizer=regularizers.l1(mu)))  # change activations?
    # model2.add(Dropout(dropout, name='drop1'))
    autoencoder.add(Dense(n_neurons, name='fc2', trainable=True, activation='relu',
                          kernel_regularizer=regularizers.l2(lambd), activity_regularizer=regularizers.l1(mu)))  # change activations?
    # model2.add(Dropout(dropout, name='drop2'))
    autoencoder.add(Dense(n_neurons, name='fc3', trainable=True, activation='relu',
                          kernel_regularizer=regularizers.l2(lambd), activity_regularizer=regularizers.l1(mu)))  # change activations? , activity_regularizer=regularizers.l1(mu)
    # model2.add(Dropout(dropout, name='drop3'))
    autoencoder.add(Dense(num_stations * t_interval, name='fc4', trainable=True, activation='relu',
                          kernel_regularizer=regularizers.l2(lambd), activity_regularizer=regularizers.l1(mu)))
    autoencoder.summary()
    # autoencoder.summary()
    # adam = Adam(lr=lr)
    # autoencoder.compile(loss='mse',
    #                     optimizer=adam)  # metrics?
    autoencoder.load_weights('/ssd/home/manuel/airquality/checkpoints/autoencoder/'
                             'tint_{}_lr_{}_lambd_{}_mu_{}_nneurons_{}.hdf5'.format(t_interval, lr, lambd, mu, n_neurons))
    return autoencoder


def train_model(experiment_id, lr, lr_lr, epochs, batch_size, t_interval, lambd, mu, n_neurons, dropout, data_days=24):
    path_log = '/ssd/home/manuel/airquality/logs/full_model/{}'.format(experiment_id)
    path_checkpoint = '/ssd/home/manuel/airquality/checkpoints/full_model/' \
                      'tint_{}_lrlr_{}_lambd_{}_mu_{}_nneurons_{}_3.hdf5'.format(t_interval, lr_lr, lambd, mu, n_neurons)

    input_dataset = '/ssd/home/manuel/airquality/data/dataset_py.hdf5'.format(t_interval)
    model = load_autoencoder(experiment_id, lr, epochs, batch_size, t_interval, lambd, mu, n_neurons, dropout)

    model.add(Dense(num_stations, name='lr', activation='relu', trainable=True))
    adam = Adam(lr=lr_lr)
    model.compile(optimizer=adam, loss='mape')

    f_dataset = h5py.File(input_dataset, 'r')
    x = f_dataset['training']['input']
    y = f_dataset['training']['output']
    print x.shape
    print y.shape
    x_val = f_dataset['validation']['input']
    y_val = f_dataset['validation']['output']

    tb_callback = TensorBoard(log_dir=path_log)
    save_model = ModelCheckpoint(filepath=path_checkpoint,
                                 monitor='val_loss',
                                 verbose=0,
                                 save_best_only=True,
                                 save_weights_only=True,
                                 mode='auto',
                                 period=1)
    early_stopping = EarlyStopping(monitor='val_loss', patience=50)
    reduce_lr = ReduceLROnPlateau(monitor='val_loss', factor=0.9,
                                  patience=1, min_lr=1e-9)
    model.load_weights('/ssd/home/manuel/airquality/checkpoints/full_model/tint_8_lrlr_1e-05_lambd_0.001_mu_1e-07_nneurons_300_2.hdf5')
    print x.shape, x_val.shape
    print y.shape, y_val.shape
    model.fit(x,
              y,
              batch_size=batch_size,
              validation_data=(x_val, y_val),
              verbose=1,
              epochs=epochs,
              shuffle='batch',
              callbacks=[tb_callback, save_model, early_stopping, reduce_lr])
    print lr_lr
    

if __name__ == '__main__':
    num_stations = 7

    parser = argparse.ArgumentParser(description='Train the RNN ')
    parser.add_argument(
        '-id',
        dest='experiment_id',
        help='Experiment ID to track and not overwrite resulting models')
    parser.add_argument(
        '-lr',
        dest='lr',
        default=1e-4,
        type=float,
        help='learning rate')
    parser.add_argument(
        '-lrlr',
        dest='lr_lr',
        default=1e-5,
        type=float,
        help='learning rate')
    parser.add_argument(
        '-e',
        dest='epochs',
        default=3000,
        type=int,
        help='epochs')
    parser.add_argument(
        '-bs',
        dest='batch_size',
        default=300,
        type=int,
        help='batch size')
    parser.add_argument(
        '-t',
        dest='t_interval',
        default=8,
        type=int,
        help='time interval')
    parser.add_argument(
        '-lb',
        dest='lambd',
        default=0.01,
        type=float,
        help='kernel regularizer')
    parser.add_argument(
        '-mu',
        dest='mu',
        default=1e-5,
        type=float,
        help='activity regularizer')
    parser.add_argument(
        '-nn',
        dest='n_neurons',
        default=300,
        type=int,
        help='neurons per layer')
    parser.add_argument(
        '-do',
        dest='dropout',
        default=0.5,
        type=float,
        help='Experiment ID to track and not overwrite resulting models')
    args = parser.parse_args()
    train_model(args.experiment_id, args.lr, args.lr_lr, args.epochs, args.batch_size, args.t_interval,
                args.lambd, args.mu, args.n_neurons, args.dropout)
