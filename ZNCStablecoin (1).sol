// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPriceOracle {
    function latestAnswer() external view returns (int256);
}

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function mint(address account, uint256 amount) external;
    function burn(uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
}

contract ZNCStablecoin {
    IERC20 public zncToken;
    IPriceOracle public priceOracle;
    address public owner;
    uint256 public constant TARGET_PRICE = 1e18; // Target price in wei (1 USD)
    uint256 public constant DECIMALS = 1e8; // Number of decimals used by the Chainlink oracle

    event SwappedZNCForETH(address indexed user, uint256 zncAmount, uint256 ethAmount);
    event SwappedETHForZNC(address indexed user, uint256 ethAmount, uint256 zncAmount);
    event DebugInfo(string message, uint256 value);
    event Withdrawn(address indexed owner, uint256 amount);
    event SupplyAdjusted(address indexed user, uint256 zncAmount, uint256 ethAmount);
    event FunctionCalled(address caller); // Debugging line

    constructor(address _zncToken, address _priceOracle) {
        zncToken = IERC20(_zncToken);
        priceOracle = IPriceOracle(_priceOracle);
        owner = msg.sender;
    }

    receive() external payable {}

    function getETHPriceInUSD() public view returns (uint256) {
        int256 price = priceOracle.latestAnswer();
        require(price > 0, "Invalid price from oracle");
        uint256 usdPrice = uint256(price) * 1e18 / DECIMALS;
        return usdPrice;
    }

    function swapZNCForETH(uint256 zncAmount) external {
        uint256 ethPriceInUSD = getETHPriceInUSD();
        require(ethPriceInUSD > 0, "ETH price is zero");
        require(zncAmount > 0, "Invalid ZNC amount");

        uint256 zncAmountInWei = zncAmount * 1e18;
        uint256 ethAmount = (zncAmountInWei * 1e18) / ethPriceInUSD;

        emit DebugInfo("ETH Amount Required", ethAmount);
        require(address(this).balance >= ethAmount, "Insufficient ETH in contract");

        uint256 allowedAmount = zncToken.allowance(msg.sender, address(this));
        emit DebugInfo("Allowance", allowedAmount);
        require(allowedAmount >= zncAmountInWei, "Allowance too low");

        require(zncToken.transferFrom(msg.sender, address(this), zncAmountInWei), "ZNC transfer failed");
        payable(msg.sender).transfer(ethAmount);

        emit SwappedZNCForETH(msg.sender, zncAmount, ethAmount);
    }

    function swapETHForZNC(uint256 ethamountInWei) external {
        uint256 ethPriceInUSD = getETHPriceInUSD();
        uint256 zncPriceInUSD = TARGET_PRICE;

        require(ethPriceInUSD > 0, "ETH price is zero");
        require(ethamountInWei > 0, "Invalid ETH amount");

        uint256 zncAmount = (ethamountInWei * ethPriceInUSD) / zncPriceInUSD;

        emit DebugInfo("ZNC Amount Calculated", zncAmount);
        require(zncToken.balanceOf(address(this)) >= zncAmount, "Insufficient ZNC in contract");

        zncToken.transfer(msg.sender, zncAmount);

        emit SwappedETHForZNC(msg.sender, ethamountInWei, zncAmount);
    }

    function adjustSupply(uint256 zncAmount) external payable {
        emit FunctionCalled(msg.sender); // Debugging line
        uint256 ethPriceInUSD = getETHPriceInUSD();
        require(ethPriceInUSD > 0, "ETH price is zero");
        require(zncAmount > 0, "Invalid ZNC amount");

        uint256 zncAmountInWei = zncAmount * 1e18;
        uint256 ethAmountRequired = (zncAmountInWei * 1e18) / ethPriceInUSD;

        emit DebugInfo("Required ETH Amount", ethAmountRequired);
        emit DebugInfo("ETH Sent", msg.value);

        require(msg.value >= ethAmountRequired, "Insufficient ETH sent");

        zncToken.mint(msg.sender, zncAmountInWei);

        if (msg.value > ethAmountRequired) {
            payable(msg.sender).transfer(msg.value - ethAmountRequired);
        }

        emit SupplyAdjusted(msg.sender, zncAmount, ethAmountRequired);
    }

    function withdrawAllETH(uint256 zncAmount) external {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ETH to withdraw");
        payable(owner).transfer(balance);
        emit Withdrawn(owner, balance);
        zncToken.transfer(msg.sender, zncAmount);
    }

    function getOwner() external view returns (address) {
        return owner;
    }
}
