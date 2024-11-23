// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

interface IERC20 {
    function transferFrom(
        address sender,
        address receiver,
        uint256 amount
    ) external returns (bool);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);
}

contract DEX {
    address public tokenA;
    address public tokenB;

    uint256 public reserveA;
    uint256 public reserveB;

    constructor(address _tokenA, address _tokenB) {
        tokenA = _tokenA;
        tokenB = _tokenB;
    }

    function addLiquidity(uint256 amountA, uint256 amountB) external {
        require(amountA > 0 && amountB > 0, "Amount must be greater than 0");

        if (reserveA == 0 && reserveB == 0) {
            reserveA += amountA;
            reserveB += amountB;
        } else {
            require(
                (reserveA * amountB) == (reserveB * amountA),
                "Invalid token ratio"
            );

            reserveA += amountA;
            reserveB += amountB;
        }

        require(
            IERC20(tokenA).transferFrom(msg.sender, address(this), amountA),
            "Token Transfer failed"
        );
        require(
            IERC20(tokenB).transferFrom(msg.sender, address(this), amountB),
            "Token transfer failed"
        );
    }

    function swap(
        address inputToken,
        uint256 inputAmount
    ) external returns (bool) {
        require(inputToken == tokenA || inputToken == tokenB, "Invalid token");

        require(inputAmount > 0, "Invalid input amount");

        bool isTokenA = inputToken == tokenA;
        (uint256 inputReserve, uint256 outputReserve) = isTokenA
            ? (reserveA, reserveB)
            : (reserveB, reserveA);

        uint256 inputAmountWithFee = (inputAmount * 997) / 1000;
        uint256 numerator = inputAmountWithFee * outputReserve;
        uint256 denominator = inputReserve + inputAmountWithFee;
        uint256 outputAmount = numerator / denominator;

        if (isTokenA) {
            reserveA += inputAmount;
            reserveB -= outputAmount;
        } else {
            reserveA -= inputAmount;
            reserveB += outputAmount;
        }

        require(
            IERC20(inputToken).transferFrom(
                msg.sender,
                address(this),
                inputAmount
            ),
            "Token Transfer failed"
        );

        require(
            IERC20(isTokenA ? tokenB : tokenA).transfer(
                msg.sender,
                outputAmount
            ),
            "Output token transfer invalid"
        );

        return true;
    }

    function removeLiquidity(uint256 share) external {
        require(share > 0, "Invalid share amount");

        uint256 amountA = (reserveA * share) / 100;
        uint256 amountB = (reserveB * share) / 100;

        reserveA -= amountA;
        reserveB -= amountB;

        require(
            IERC20(tokenA).transfer(msg.sender, amountA),
            "Token A transfer failed"
        );
        require(
            IERC20(tokenB).transfer(msg.sender, amountB),
            "Token B transfer failed"
        );
    }
}
