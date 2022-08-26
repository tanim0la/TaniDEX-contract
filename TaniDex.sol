// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract taniDex is ERC20 {
    
    address public gouTokenAddress;

    constructor(address _gouToken) ERC20("GOU LP Token", "GOULP") {
        require(_gouToken != address(0), "Token address passed is a nul address");
        gouTokenAddress = _gouToken;
    }

    /**
    * @dev Returns the amount of `Gou Tokens` held by the contract
    */
    function getReserve() public view returns (uint) {
        return ERC20(gouTokenAddress).balanceOf(address(this));
    }

    /**
    * @dev Adds liquidity to the exchange.
    */
    function addLiquidity(uint _amount) public payable returns (uint) {
            uint liquidity;
            uint ethBalance = address(this).balance;
            uint gouTokenReserve = getReserve();
            ERC20 gouAddress = ERC20(gouTokenAddress);

            if(gouTokenReserve == 0) {
                gouAddress.transferFrom(msg.sender, address(this), _amount);

                liquidity = ethBalance;
                _mint(msg.sender, liquidity);
            } else {
                uint ethReserve =  ethBalance - msg.value;
                uint gouAmount = (msg.value * gouTokenReserve) / ethReserve;

                require(_amount >= gouAmount, "Amount of tokens sent is less than the minimum tokens required");

                gouAddress.transferFrom(msg.sender, address(this), gouAmount);

                liquidity = (totalSupply() * msg.value)/ ethReserve;
                _mint(msg.sender, liquidity);
            }

            return liquidity;
    }

    /** 
    * @dev Returns the amount Eth/Gou tokens that would be returned to the user
    * in the swap
    */
    function removeLiquidity(uint _amount) public returns (uint , uint) {
        require(_amount > 0, "_amount should be greater than zero");
        uint ethReserve = address(this).balance;
        uint _totalSupply = totalSupply();
        uint ethAmount = (ethReserve * _amount) / _totalSupply;
        uint gouAmount = (getReserve() * _amount) / _totalSupply;

        // Burn the sent LP tokens from the user's wallet because they are already sent to
        // remove liquidity
        _burn(msg.sender, _amount);

        // Transfer `ethAmount` of Eth from user's wallet to the contract
        payable(msg.sender).transfer(ethAmount);

        // Transfer `gouAmount` of Gou tokens from the user's wallet to the contract
        ERC20(gouTokenAddress).transfer(msg.sender, gouAmount);
        return (ethAmount, gouAmount);
    }

    /**
    * @dev Returns the amount Eth || GOU tokens that would be returned to the user
    * in the swap
    */
    function getAmountOfTokens(
        uint256 inputAmount,
        uint256 inputReserve,
        uint256 outputReserve
    ) public pure returns (uint256) {
        require(inputReserve > 0 && outputReserve > 0, "invalid reserves");
        uint256 inputAmountWithFee = inputAmount * 99;
        uint256 numerator = inputAmountWithFee * outputReserve;
        uint256 denominator = (inputReserve * 100) + inputAmountWithFee;

        return numerator / denominator;
    }

    /** 
    * @dev Swaps Eth for Gou Tokens
    */
    function ethToGouToken(uint _minTokens) public payable {
        uint gouReserve = getReserve();

        uint gouAmount = getAmountOfTokens(
                                msg.value, 
                                address(this).balance - msg.value, 
                                gouReserve);

        require(gouAmount >= _minTokens, "insufficient output amount");
        // Transfer the `Gou` tokens to the user
        ERC20(gouTokenAddress).transfer(msg.sender, gouAmount);
    }

    /** 
    * @dev Swaps Gou Tokens for Eth  
    */
    function gouTokenToEth(uint gouAmount, uint _minEth) public {
        uint gouReserve = getReserve();

        uint ethAmount = getAmountOfTokens(
                                gouAmount, 
                                gouReserve, 
                                address(this).balance);

        require(ethAmount >= _minEth, "insufficient output amount");
        // Transfer `Gou` tokens from the user's address to the contract
        ERC20(gouTokenAddress).transferFrom(
            msg.sender,
            address(this),
            gouAmount
        );

        // Transfer Eth to the user's address
        payable(msg.sender).transfer(ethAmount);
    }

}