const AWS = require('aws-sdk');

AWS.config.update({ region: 'us-east-1' });
const ec2 = new AWS.EC2({ apiVersion: '2016-11-15' });
const params = {
    InstanceIds: ['i-08537b33c66b2b439'],
};
exports.startEC2Instance = () => {
    return ec2.startIntances(params, function (err, data) {
        if (err) {
            console.log("Error", err, err.stack);
        } else {
            console.log("Success", data.StartingInstances);
        }
    });
};

exports.stopEC2Instance = () => {
    return ec2.stopInstances(params, function (err, data) {
        if (err) {
            console.log("Error", err, err.stack);
        } else {
            console.log("Success", data.StoppingInstances);
        }
    });
};
