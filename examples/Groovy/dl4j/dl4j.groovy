/*
 * This script is executed by 'dl4j.R'. See that script for details.
 * Similar examples that illustrate data operations on the Java side can
 * be found at 
 *
 * https://github.com/deeplearning4j/dl4j-examples/blob/master/dl4j-examples/src/main/java/org/deeplearning4j/examples/dataexamples/CSVExample.java
 *
 * and
 * 
 * https://github.com/deeplearning4j/dl4j-examples/blob/master/dl4j-examples/src/main/java/org/deeplearning4j/examples/feedforward/mnist/MLPMnistTwoLayerExample.java
 * 
 * A good (maybe slightly outdated) reference for hyperparameters can be found at
 * 
 * https://deeplearning4j.org/docs/latest/deeplearning4j-troubleshooting-training
*/

import org.deeplearning4j.eval.Evaluation;
import org.deeplearning4j.nn.conf.MultiLayerConfiguration;
import org.deeplearning4j.nn.conf.NeuralNetConfiguration;
import org.deeplearning4j.nn.conf.layers.DenseLayer;
import org.deeplearning4j.nn.conf.layers.OutputLayer;
import org.deeplearning4j.nn.multilayer.MultiLayerNetwork;
import org.deeplearning4j.nn.weights.WeightInit;
import org.nd4j.linalg.activations.Activation;
import org.nd4j.linalg.api.ndarray.INDArray;
import org.nd4j.linalg.cpu.nativecpu.NDArray;
import org.nd4j.linalg.dataset.DataSet;
import org.nd4j.linalg.learning.config.Sgd;
import org.nd4j.linalg.lossfunctions.LossFunctions;

/*
 * Retrieve the train and test data sets from the R environment to create the 
 * DataSet structures expected by DL4J.
*/
DataSet train = new DataSet(new NDArray(R.get("train")), new NDArray(R.get("train.labels")));
DataSet test = new DataSet(new NDArray(R.get("test")), new NDArray(R.get("test.labels")));

/*
 * Configure a feedforward neural network with a softmax output activation function.
 * Layers: input (4), hidden (7), hidden (3), output (3).
 * See https://deeplearning4j.org/docs/latest/deeplearning4j-troubleshooting-training
 * for information about hyperparameters.
*/
MultiLayerConfiguration conf = new NeuralNetConfiguration.Builder()
    .seed(R.get("seed").intValue())
    .activation(Activation.TANH)
    .weightInit(WeightInit.XAVIER)
    .updater(new Sgd(0.1)) // Learning rate.
    .list()
    .layer(new DenseLayer.Builder().nIn(4).nOut(7).build())
    .layer(new DenseLayer.Builder().nIn(7).nOut(3).build())
    .layer(
        new OutputLayer.Builder(LossFunctions.LossFunction.NEGATIVELOGLIKELIHOOD)
            .activation(Activation.SOFTMAX)
            .nIn(3)
            .nOut(3)
            .build()
      )
    .backprop(true)
    .build();

/*
 * Initialize and train model.
*/
MultiLayerNetwork model = new MultiLayerNetwork(conf);
model.init();

for (int i = 0; i < 200; i++) {
    model.fit(train);
}

/*
 * Evaluate the model against test data and show the results.
*/
Evaluation eval = new Evaluation(3);
INDArray output = model.output(test.getFeatures());
eval.eval(test.getLabels(), output);
eval.stats();

