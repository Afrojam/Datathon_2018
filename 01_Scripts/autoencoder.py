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
from keras.callbacks import ModelCheckpoint, TensorBoard, EarlyStopping
from keras import regularizers
import h5py
import argparse
from keras.losses import kullback_leibler_divergence, mse

# experiment_id = 1


# TO TEST:
# activations(sigmoid vs relu(bad?)) vs no activations(paper)
# loss
# batch_size
# change lambda and mu?
# no last regularization?


# def custom_loss(y_true, y_pred):
#     return kullback_leibler_divergence(y_true, y_pred) + mse(y_true, y_pred)
#

def train_autoencoder(experiment_id, lr, epochs, batch_size, t_interval, lambd, mu, n_neurons, dropout, data_days=24):
    path_log = '/ssd/home/manuel/airquality/logs/autoencoder/' \
               'tint_{}_lr_{}_lambd_{}_mu_{}_nneurons_{}'.format(t_interval, lr, lambd, mu, n_neurons)
    path_checkpoint = '/ssd/home/manuel/airquality/checkpoints/autoencoder/' \
                      'tint_{}_lr_{}_lambd_{}_mu_{}_nneurons_{}.hdf5'.format(t_interval, lr, lambd, mu, n_neurons)

    input_dataset = '/ssd/home/manuel/airquality/data/dataset_py.hdf5'  # ???

    autoencoder = Sequential()
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
                          kernel_regularizer=regularizers.l2(lambd), activity_regularizer=regularizers.l1(mu)))  # change activations?/no activation?
    autoencoder.summary()
    adam = Adam(lr=lr)

    # autoencoder.compile(loss=custom_loss,
    # autoencoder.compile(loss=['mse', 'klp'],
    autoencoder.compile(loss='mse',
                        optimizer=adam,
                        metrics=['mse'])  # metrics?

    # callbacks
    tb_callback = TensorBoard(log_dir=path_log)
    save_model = ModelCheckpoint(filepath=path_checkpoint,
                                 monitor='val_loss',
                                 verbose=0,
                                 save_best_only=True,
                                 save_weights_only=True,
                                 mode='auto',
                                 period=1)
    early_stopping = EarlyStopping(monitor='val_loss', patience=3)

    f_dataset = h5py.File(input_dataset, 'r')
    x = f_dataset['training']['input']

    x_val = f_dataset['validation']['input']

    print x.shape, x_val.shape
    autoencoder.fit(x,
                    x,
                    batch_size=batch_size,
                    validation_data=(x_val, x_val),
                    verbose=1,
                    epochs=epochs,
                    shuffle='batch',
                    callbacks=[tb_callback, save_model, early_stopping])


if __name__ == '__main__':
    # dropout = 0.5
    # n_neurons = 300
    # t_interval = 4
    # lr = 0.0001
    # epochs = 3000
    # batch_size = 300  # ??
    # lambd = 0.01
    # mu = 1e-5
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
    train_autoencoder(args.experiment_id, args.lr, args.epochs, args.batch_size, args.t_interval,
                      args.lambd, args.mu, args.n_neurons, args.dropout)
