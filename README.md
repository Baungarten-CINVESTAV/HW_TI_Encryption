# CSAW Competition: AI Hardware Attack Challenge

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0) [![UPRJ_CI](https://github.com/efabless/caravel_project_example/actions/workflows/user_project_ci.yml/badge.svg)](https://github.com/efabless/caravel_project_example/actions/workflows/user_project_ci.yml)

Author: Emilio Baungarten

<p align="center">
<img src="https://github.com/Baungarten-CINVESTAV/HW_TI_Encryption/blob/main/HTML_Docs/source/images/HardwareTrojan1.png" width=50% height=50%>
</p>

## Objective:

<p align="justify">
The project encompasses the development of a Verilog module designed to store encryption keys used in various encryption algorithms. This module is engineered to support popular encryption algorithms, including Advanced Encryption Standard (AES), Data Encryption Standard (DES), and Secure Hash Algorithm (SHA). These algorithms play a pivotal role in securing sensitive data and communications across various applications.

One noteworthy aspect of this project is the utilization of a feature called Large Language Model (LLM) to modify the behavior of the Verilog module. This modification inserts a Trojan at the Register Transfer Level (RTL) level, changing the module's capabilities by enabling the storage of the last eight keys used in the previous encryption algorithms, AES, DES, and SHA. This adaptation empowers the module to offer key management, allowing third-person access and reusing recent encryption keys. As a result, it violates the efficiency and convenience of cryptographic operations, particularly in scenarios where frequent keys are necessary.

</p>

## Documentation


<p align="center">
Comprehensive documentation and a step-by-step explanation of the project's development can be accessed at the following URL: 
  
[https://hw-ti-encryption.readthedocs.io/en/latest/](https://hw-ti-encryption.readthedocs.io/en/latest/)
  
</p>
