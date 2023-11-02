.. _Chapter_2:

=========
Objective
=========

The project encompasses the development of a Verilog module designed to store encryption keys used in various encryption algorithms. This module is engineered to support popular encryption algorithms, including Advanced Encryption Standard (AES), Data Encryption Standard (DES), and Secure Hash Algorithm (SHA). These algorithms play a pivotal role in securing sensitive data and communications across various applications.

One noteworthy aspect of this project is the utilization of a feature called Large Language Model (LLM) to modify the behavior of the Verilog module. This modification inserts a Trojan at the Register Transfer Level (RTL) level, changing the module's capabilities by enabling the storage of the last eight keys used in the previous encryption algorithms, AES, DES, and SHA. This adaptation empowers the module to offer key management, allowing third-person access and reusing recent encryption keys. As a result, it violates the efficiency and convenience of cryptographic operations, particularly in scenarios where frequent keys are necessary.



