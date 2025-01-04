const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("EduConnectModule", (m) => {

  const lock = m.contract("EduConnect");

  return { lock };
});
