const { EC2Client, StartInstancesCommand } = require("@aws-sdk/client-ec2");

const ec2 = new EC2Client();

exports.startEC2Instance = async (event) => {
  const instanceId = process.env.INSTANCE_ID;
  const command = new StartInstancesCommand({ InstanceIds: [instanceId] });
  const response = await ec2.send(command);
  console.log("StartInstances response:", JSON.stringify(response));
  return response;
};
