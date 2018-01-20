"""
Description:

Owner : Manuel Sarmiento
Creation Date : 20/01/18
Last Contributor : 
Last Modification : 
"""

import os
import subprocess as sp
import pandas as pd
from join_models import predict

days = pd.date_range('2015-01-03 00:00:00', '2015-12-31 00:00:00', freq='3D')

predictions = []
for day in days:
    pred = predict(day)
    predictions.append(pred)
