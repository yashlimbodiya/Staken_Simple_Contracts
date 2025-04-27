import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title SimpleStaking
 * @dev Contract that allows users to stake ERC20 tokens and earn block-based rewards.
 */
contract SimpleStaking is Ownable {
    IERC20 public stakingToken;
    uint256 public rewardRatePerBlock; // Reward given per block, scaled to 1e18

    struct StakeInfo {
        uint256 amount;           // Amount of tokens staked
        uint256 rewardDebt;        // Accumulated but unpaid rewards
        uint256 lastStakedBlock;   // Block number when last staked or claimed
    }

    mapping(address => StakeInfo) public stakes;

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount, uint256 reward);

    /**
     * @param _stakingToken Address of the ERC20 staking token
     * @param _rewardRatePerBlock Rewards distributed per block per token staked
     * @param initialOwner Owner of the staking contract
     */
    constructor(address _stakingToken, uint256 _rewardRatePerBlock, address initialOwner) Ownable(initialOwner) {
        require(_stakingToken != address(0), "Invalid token address");
        require(_rewardRatePerBlock > 0, "Invalid reward rate");

        stakingToken = IERC20(_stakingToken);
        rewardRatePerBlock = _rewardRatePerBlock;
    }
    /**
     * @dev Stake specified amount of tokens
     */
    function stake(uint256 _amount) external {
        require(_amount > 0, "Cannot stake 0 tokens");

        StakeInfo storage user = stakes[msg.sender];

        if (user.amount > 0) {
            uint256 pendingReward = calculateReward(msg.sender);
            user.rewardDebt += pendingReward;
        }

        stakingToken.transferFrom(msg.sender, address(this), _amount);

        user.amount += _amount;
        user.lastStakedBlock = block.number;

        emit Staked(msg.sender, _amount);
    }

    /**
     * @dev Unstake specified amount and claim rewards
     */
    function unstake(uint256 _amount) external {
        StakeInfo storage user = stakes[msg.sender];
        require(user.amount >= _amount, "Not enough staked");

        uint256 pendingReward = calculateReward(msg.sender);
        uint256 totalReward = pendingReward + user.rewardDebt;

        user.amount -= _amount;
        user.rewardDebt = 0;
        user.lastStakedBlock = block.number;

        stakingToken.transfer(msg.sender, _amount);

        if (totalReward > 0) {
            stakingToken.transfer(msg.sender, totalReward);
        }

        emit Unstaked(msg.sender, _amount, totalReward);
    }

    /**
     * @dev Calculate pending rewards for a user (internal helper)
     */
    function calculateReward(address _user) public view returns (uint256) {
        StakeInfo storage user = stakes[_user];
        uint256 blocksPassed = block.number - user.lastStakedBlock;
        return (user.amount * rewardRatePerBlock * blocksPassed) / 1e18;
    }

    /**
     * @dev View function to check total pending rewards for a user
     */
    function pendingRewards(address _user) external view returns (uint256) {
        StakeInfo storage user = stakes[_user];
        uint256 pendingReward = calculateReward(_user);
        return pendingReward + user.rewardDebt;
    }
}
