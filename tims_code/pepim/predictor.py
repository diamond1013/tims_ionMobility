from . import models

import pandas as pd

class PeptideIonMobilityPredictor:

    def __init__(self, model_path=None, model=None, im_min=0.5, im_max=1.5):
        if model_path is not None:
            model = models.load_model(model_path)
        elif model is None:
            model = models.build_model()        
        self.model = model
        self.im_min = im_min
        self.im_max = im_max

    def predict(self, sequences):
        pred = models.predict(self.model, sequences, im_min=self.im_min, im_max=self.im_max)
        return pd.DataFrame.from_items([
            ('sequence', sequences),
            ('ionMobility', pred.flatten())
        ])

    def load_weights(self, path=None):
        self.model.load_weights(path)