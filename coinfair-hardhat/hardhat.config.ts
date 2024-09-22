import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import 'hardhat-tracer';

const config: HardhatUserConfig = {
  solidity: {
    compilers:[
      {
        version:"0.5.16",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        }
      },
      {
        version:"0.6.6",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        }
      },
      {
        version:"0.8.24",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        }
      }]
  },
};

export default config;
