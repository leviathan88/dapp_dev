var MyBallot = artifacts.require('MyBallot')

module.exports = function(deployer) {
  deployer.deploy(MyBallot, 4)
}