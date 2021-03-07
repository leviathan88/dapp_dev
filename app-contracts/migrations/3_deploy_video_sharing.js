var VideoSharingContract = artifacts.require('VideoSharingContract')

module.exports = function(deployer) {
  deployer.deploy(VideoSharingContract)
}