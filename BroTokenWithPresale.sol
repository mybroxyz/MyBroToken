/// SPDX-License-Identifier: MIT
/// Compatible with OpenZeppelin Contracts ^5.0.0

/**
* This includes presale logic for the $BRO token launch on LFG.gg on Avalanche.
* 
* Users can transfer AVAX directly to this contract address during the presale time window.
* 
* There is a minimum presale buy in amount of 1 AVAX per transfer.
* 
* LP to be trustlessly created after the presale ends, 
* using half of the $BRO supply and all of the presale AVAX.
* 
* Note: There are no whale limits or allowlists for the presale, 
* to allow for open and dynamic presale AVAX collection size ("Fair Launch" style presale).
* 
* LP is burned since LP fees are automatically converted to more LP for LFJ TraderJoe V1 LPs.
* 
* Presale buyers' $BRO tokens can be trustlessly "airdropped" out after presale ends.
*/

/**
* Base token contract imports created with https://wizard.openzeppelin.com/
* 
* This contract attempts to conform to Solidity naming convention guidelines, NatSpec comments,
* and layout ordering, et cetera, as per the Solidity Style Guide:
* https://docs.soliditylang.org/en/stable/style-guide.html#naming-conventions
*/
pragma solidity 0.8.28;

/// OpenZeppelin Contracts (last updated v5.0.0+)
import "@openzeppelin/contracts/token/ERC20/ERC20.sol"; 
/// OpenZeppelin Contracts (last updated v5.0.0+)
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol"; 
/// OpenZeppelin Contracts (last updated v5.1.0)
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol"; 


interface IUniswapV2Factory {

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);


    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
}


/// TraderJoe version of Uniswap code which has AVAX instead of ETH in the function names
interface ITJUniswapV2Router01 {

    function factory() external pure returns (address);


    function addLiquidityAVAX(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountAVAX,
            uint256 liquidity
        );
}


/**
⠀⠀⠀⠀⠀⠀⠀⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⣼⣷⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣾⣧⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⢸⣿⣿⣷⡀⠀⠀⠀⠀⣀⣀⠀⠀⠀⠀⢀⣾⣿⣿⡇⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠈⢿⣿⣿⣿⣷⠀⣠⣾⣿⣿⣷⣄⠀⣾⣿⣿⣿⡿⠁⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠈⠛⠿⠁⣼⣿⣿⣿⣿⣿⣿⣧⠈⠿⠛⠁⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⢀⡀ ⠘⠛⠛⠛⠛⠛⠛⠛⠃⢀⡀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⣼⠏⠀⠿⣿⣶⣶⣶⣶⣿⠿⠀⠹⣷⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⢰⡟⠀⣴⡄⠀⣈⣹⣏⣁⡀⢠⣦⠀⢻⣇⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠈⠀⠐⢿⣿⠿⠿⠿⠿⠿⠿⣿⡿⠂⠀⠙⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⢀⣴⣿⣷⣄⠉⢠⣶⠒⠒⣶⡄⠉⣠⣾⣿⣦⡀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⢀⣴⣿⣿⣿⣿⣿⣷⣿⣿⣿⣿⣿⣿⣾⣿⣿⣿⣿⣿⣦⡀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠚⠛⠛⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠛⠛⠓⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠙⢿⣿⣿⡿⠋⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀


    /$$    /$$$$$$$  /$$$$$$$   /$$$$$$ 
  /$$$$$$ | $$__  $$| $$__  $$ /$$__  $$
 /$$__  $$| $$  \ $$| $$  \ $$| $$  \ $$
| $$  \__/| $$$$$$$ | $$$$$$$/| $$  | $$
|  $$$$$$ | $$__  $$| $$__  $$| $$  | $$
 \____  $$| $$  \ $$| $$  \ $$| $$  | $$
 /$$  \ $$| $$$$$$$/| $$  | $$|  $$$$$$/
|  $$$$$$/|_______/ |__/  |__/ \______/  
 \_  $$_/                                                                                                           
   \__/                                                                                                             

*/


/// Main contract for the $BRO token with presale airdrop and LP seeding
contract BroTokenWithPresale is ERC20, ERC20Permit, ReentrancyGuard {

    /// 420690000000000000000000000000000 token supply in WEI, to mint in the constructor
    /// 420.69 Trillion in 18 decimal precision, 420,690,000,000,000 . 000,000,000,000,000,000
    uint256 private constant MINT_420_TRILLION_690_BILLION_WEI = 420690 * (10**9) * (10**18);

    /// BRO token total supply amount to mint to this contract in constructor
    uint256 private constant TOTAL_SUPPLY_TO_MINT = MINT_420_TRILLION_690_BILLION_WEI;

    /// 50% of BRO supply is for the presale buyers
    uint256 private constant FIFTY_PERCENT = 50;

    /// 50% of BRO supply calculated as (TOTAL_SUPPLY_TO_MINT * 50) / 100
    uint256 public constant PRESALERS_BRO_SUPPLY = (TOTAL_SUPPLY_TO_MINT * FIFTY_PERCENT) / 100;

    /// Remaining BRO is for automated LP
    uint256 public constant LP_BRO_SUPPLY = TOTAL_SUPPLY_TO_MINT - PRESALERS_BRO_SUPPLY;

    /// Launch on December's New Moon zenith
    /// Unix timestamp of Mon Dec 30 2024 05:27:00 GMT-0500 (EST)
    uint256 private constant NEW_MOON_TIME = 1735554420;

    /// Whitelist phase start time in unix timestamp
    uint256 public constant IDO_START_TIME = NEW_MOON_TIME;

    /// 2 hours before IDO_START_TIME to prepare for IDO by seeding LP,
    /// and giving some time for users to collect their tokens from the presale
    uint256 private constant HOURS_TO_PREP_IDO = 2 hours;

    /// Cutoff time to buy into the presale, must be before IDO_START_TIME
    uint256 public constant PRESALE_END_TIME = IDO_START_TIME - HOURS_TO_PREP_IDO;

    /// Buffer for miner timestamp variance
    uint256 private constant TIMESTAMP_BUFFER = 1 minutes;

    /// Date LP seeding and presale tokens dispersal can begin, after presale ends,
    /// plus a time buffer since miners can vary timestamps slightly
    uint256 public constant SEEDING_TIME = PRESALE_END_TIME + TIMESTAMP_BUFFER;

    /// Length of time the whitelist phase will last, 5 minutes is 300 seconds
    uint256 private constant LENGTH_OF_WL_PHASE = 5 minutes;

    /// End of whitelist phase in unix timestamp
    uint256 public constant WL_END_TIME = IDO_START_TIME + LENGTH_OF_WL_PHASE;

    /// 1 AVAX in WEI
    uint256 private constant ONE_AVAX = 1000000000000000000;

    /// 1 AVAX in WEI minimum buy, to prevent micro buy spam attack hurting the airdrop phase
    uint256 public constant MINIMUM_BUY = ONE_AVAX;

    /// Total phases for IDO launch
    /// Phase 0 is the presale
    /// Phase 1 is LP seeding
    /// Phase 2 is presale token dispersal
    /// Phase 3 is the whitelist IDO launch
    /// Phase 4 is public trading
    uint256 public constant TOTAL_PHASES = 4;

    /// Burn LP by sending it to this address
    address public constant DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    /// WAVAX C-Chain Mainnet: 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7
    /// WAVAX Fuji Testnet: 0xd00ae08403B9bbb9124bB305C09058E32C39A48c
    address public constant WAVAX_ADDRESS = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;

    /// Main BRO/AVAX LP dex router
    /// TraderJoe router C-Chain Mainnet: 0x60aE616a2155Ee3d9A68541Ba4544862310933d4
    /// TraderJoe router Fuji Testnet: 0xd7f655E3376cE2D7A2b08fF01Eb3B1023191A901
    address public constant ROUTER_ADDRESS = 0x60aE616a2155Ee3d9A68541Ba4544862310933d4;

    /// Swap with pair BRO/WAVAX
    address public immutable LFJ_V1_PAIR_ADDRESS;

    /// DEX router interface for swapping BRO and making LP on lfj.gg TraderJoe V1 router
    ITJUniswapV2Router01 public immutable LFJ_V1_ROUTER;

    /// Array to store presale buyers addresses to send BRO tokens to later
    address[] public presaleBuyers = new address[](0);

    /// Flag for if LP is seeded
    bool public lpSeeded = false;

    /// Flag to indicate when airdrop is completed
    bool public airdropCompleted = false;

    /// Count through the airdrop array when sending out tokens
    uint256 public airdropIndex = 0;

    /// Count total AVAX in WEI received during presale
    uint256 public totalAvaxPresale = 0;

    /// True if user is a previous presale buyer
    mapping(address => bool) public previousBuyer;

    /// Airdrop array slot of the presale buyer
    mapping(address => uint256) public airdropSlot;

    /// Total AVAX in WEI sent by presale buyers
    mapping(address => uint256) public totalAvaxUserSent;

    /// True if user has received their presale tokens already
    mapping(address => bool) public userHasClaimed;

    /// BRO tokens received per user during WL phase
    mapping(address => uint256) public userTokensFromWL;


    event AirdropCompleted(
        address indexed caller
    );


    event LPSeeded(
        address indexed caller,
        uint256 avaxAmount,
        uint256 broAmount
    );


    event BuyerAdded(
        address indexed buyer
    );


    event PresaleBought(
        address indexed buyer,
        uint256 amount
    );


    event AvaxWithdraw(
        address indexed to,
        uint256 amount
    );


    event TokensClaimed(
        address indexed to,
        uint256 amount
    );


    event DustSent(
        address indexed to,
        uint256 amount
    );


    /// Check if presale has ended plus the buffer time
    modifier afterPresale() {
        /// Cannot calculate token ratios until all AVAX is collected and presale ends
        require(block.timestamp >= SEEDING_TIME, "Presale time plus buffer has not yet ended");
        _;
    }


    /// Check if LP has been seeded
    modifier seeded() {
        require(lpSeeded, "LP has not yet been seeded");
        _;
    }


    /// Check if LP has not been seeded
    modifier notSeeded() {
        require(!lpSeeded, "LP has already been seeded");
        _;
    }


    /// @dev This ERC20 constructor creates our BRO token name and symbol.
    constructor()
        ERC20("My Bro", "BRO")
        ERC20Permit("My Bro")
    {
        require(IDO_START_TIME > block.timestamp + 3 hours, "IDO_START_TIME must be > 3 hours from now");
        require(IDO_START_TIME < block.timestamp + 21 days, "IDO_START_TIME must be < 21 days from now");
        ITJUniswapV2Router01 _lfjV1Router;
        address _lfjV1PairAddress;
        _lfjV1Router = ITJUniswapV2Router01(ROUTER_ADDRESS);
        /// Initialize Uniswap V2 BRO/WAVAX LP pair, with 0 LP tokens in it to start with
        _lfjV1PairAddress = IUniswapV2Factory(_lfjV1Router.factory()).createPair(address(this), WAVAX_ADDRESS);
        LFJ_V1_ROUTER = _lfjV1Router;
        LFJ_V1_PAIR_ADDRESS = _lfjV1PairAddress;
        /// Mint total supply to this contract, to later make LP and do the presale BRO dispersal
        super._update(address(0), address(this), TOTAL_SUPPLY_TO_MINT);
    }



    /// Receive and/or fallback public functions:


    /**
     * @dev The user's wallet will add extra gas when transferring AVAX.
     * We aren't restricted to only sending an event.
     * Note that nonReentrant is called in the internal _buyPresale.
     * This function is used to receive AVAX from users for the presale.
     */
    receive() external payable {
        _buyPresale(msg.value, msg.sender);
    }



    /// External functions:


    /**
     * @dev Seeds liquidity pool after presale ends. Must be called once.
     * No arguments, no return. Approves tokens and adds liquidity with collected AVAX.
     * Reverts if called before presale ended or if LP already seeded.
     */
    function seedLP() external nonReentrant afterPresale notSeeded {
        /// Approve BRO tokens for transfer by the router
        _approve(address(this), ROUTER_ADDRESS, LP_BRO_SUPPLY);
        /// Seed LFJ V1 LP with all AVAX collected during the presale
        try LFJ_V1_ROUTER.addLiquidityAVAX{value: totalAvaxPresale}( 
            address(this), 
            /// Seed with remaining BRO supply not assigned to airdrop to presale buyers
            LP_BRO_SUPPLY, 
            /// Infinite slippage
            0, 
            0,
            DEAD_ADDRESS,
            block.timestamp
        ) {
        } catch {
            revert(string("seedLP() failed"));
        }
        lpSeeded = true;
        emit LPSeeded(msg.sender, totalAvaxPresale, LP_BRO_SUPPLY);
    }


    /**
     * @dev Public alternative to `receive()`. Buys presale tokens by sending AVAX.
     * Note that nonReentrant is called in the internal _buyPresale.
     * Reverts if presale ended or user sent less than MINIMUM_BUY.
     */
    function buyPresale() external payable {
        _buyPresale(msg.value, msg.sender);
    }


    /**
     * @dev Allows user to emergencyWithdraw their AVAX before presale ends and LP seeded.
     * Resets user's presale deposit to 0 and removes them from the airdrop array.
     * Reverts if user has no AVAX deposited or LP is seeded.
     */
    function emergencyWithdraw() external nonReentrant notSeeded {
        address _withdrawer = msg.sender;
        uint256 _avaxFromUser = totalAvaxUserSent[_withdrawer];
        require(_avaxFromUser > 0, "No AVAX to withdraw");
        /// Reset user's total AVAX deposited to 0
        totalAvaxUserSent[_withdrawer] = 0; 
        /// Subtract user's AVAX from total AVAX received by all users
        totalAvaxPresale -= _avaxFromUser; 
        /// Remove user from presaleBuyers airdrop array
        _popAndSwapAirdrop(_withdrawer); 
        /// Send back the user's AVAX deposited
        payable(_withdrawer).transfer(_avaxFromUser); 
        /// Set user status to not being a previous buyer anymore
        previousBuyer[_withdrawer] = false; 
        emit AvaxWithdraw(_withdrawer, _avaxFromUser);
    }


    /**
     * @dev Airdrops tokens to presale buyers in batches. 
     * `_maximumTransfers` sets how many addresses to process this call.
     * Reverts if airdrop already completed or presale not ended.
     */
    function airdropBuyers(uint256 _maximumTransfers) external nonReentrant afterPresale seeded {
        require(!airdropCompleted, "Airdrop has already been completed");
        _airdrop(_maximumTransfers);
    }


    /**
     * @dev Claim tokens for a single user (pull method).
     * @param _claimer Address of the presale buyer to receive tokens.
     * We will allow anyone to send a single user their tokens due.
     * Reverts if user has no tokens to claim or already claimed. 
     * Also reverts if presale not ended or LP not seeded.
     */
    function claimTokens(address _claimer) external nonReentrant afterPresale seeded {
        uint256 _usersPresaleTokens = presaleTokensPurchased(_claimer);
        require(_usersPresaleTokens > 0, "No tokens to claim");
        require(!userHasClaimed[_claimer], "User has already received their BRO tokens");
        userHasClaimed[_claimer] = true;
        /// Remove user from presaleBuyers array so they don't get airdropped
        _popAndSwapAirdrop(_claimer); 
        /// Send tokens from contract itself to the presale buyer
        _transfer(address(this), _claimer, _usersPresaleTokens); 
        emit TokensClaimed(_claimer, _usersPresaleTokens);
        if (airdropIndex >= presaleBuyers.length) {
            airdropCompleted = true;
            /// Send any leftover token dust to the last claimant
            sendDust(_claimer);
            emit AirdropCompleted(_claimer);
        }
    }



    /// Public functions:


    /// @dev Checks if trading is active (LP seeded + IDO_START_TIME reached).
    function tradingActive() public view returns (bool) {
        return (lpSeeded && block.timestamp >= IDO_START_TIME);
    }


    /// @dev Checks if in restricted whitelist phase.
    function tradingRestricted() public view returns (bool) {
        return (tradingActive() && block.timestamp <= (WL_END_TIME));
    }


    /// @dev Returns current trading phase [0,1,2,3,4] .
    function tradingPhase() public view returns (uint256) {
        uint256 _timeNow = block.timestamp;
        if (!tradingActive()) {
            if (_timeNow < SEEDING_TIME) {
                /// Presale time plus buffer is not completed yet
                return 0;
            } else if (!lpSeeded) {
                /// LP seeding can begin
                return 1; 
            } else {
                /// Presale airdrop token dispersal
                return 2; 
            }
        } else if (tradingRestricted()) {
            /// Whitelist IDO phase
            return 3; 
        } else {
            /// Public trading
            return 4; 
        }
    }


    /**
     * @dev Calculate amount of BRO tokens the user will be due from the presale.
     * @param _purchaser Address of the presale purchaser.
     * @return Amount of BRO tokens owed to `_purchaser`.
     * Reverts if presale has not ended yet (`afterPresale`).
     */ 
    function presaleTokensPurchased(address _purchaser) public view afterPresale returns (uint256) {
        /// Note we cannot precalculate and save this value, as we don't know the total AVAX until presale ends
        /// Also if we did save the value that would cost more gas than calculating it here on the fly
        return (totalAvaxUserSent[_purchaser] * PRESALERS_BRO_SUPPLY) / totalAvaxPresale;
    }



    /// Internal functions:


    /// @dev BRO transfer check. Overriding ERC20 `_update` for presale and IDO WL logic.
    function _update(
        address from_,
        address to_,
        uint256 amount_
    ) internal override(ERC20) {
        if (amount_ == 0) {
            super._update(from_, to_, 0);
            return;
        }
        uint256 _tradingPhase = tradingPhase();
        /// Don't limit public phase 4 trading
        if (_tradingPhase >= TOTAL_PHASES) {
            super._update(from_, to_, amount_);
            return;
        }
        /// Don't limit initial LP seeding, or the presale tokens dispersal
        if (from_ == address(this) && _tradingPhase > 0) {
            super._update(from_, to_, amount_);
            return;
        }
        /// Check if user is allowed in WL phase 3
        _beforeTokenTransfer(to_, amount_, _tradingPhase);
        super._update(from_, to_, amount_);
    }



    /// Private functions:


    /// @dev Remove user from presaleBuyers array.
    function _popAndSwapAirdrop(address removedUser_) private { 
        /// Get slot of user to remove from airdrop array presaleBuyers
        uint256 slot_ = airdropSlot[removedUser_]; 
        /// Get the last index of the array
        uint256 lastIndex_ = presaleBuyers.length - 1; 
        /// If the user to remove is the last user in the array
        if (slot_ == lastIndex_) { 
            /// Remove the user from the array
            presaleBuyers.pop(); 
            return;
        }
        /// Get the last user in the array
        address lastUser_ = presaleBuyers[lastIndex_]; 
        /// Remove the duplicated last user from the array
        presaleBuyers.pop(); 
        /// Swap the duplicated user in the array with the user to remove
        presaleBuyers[slot_] = lastUser_; 
        /// Update the slot mapping of the duplicated user
        /// Note we do not reset the slot mapping of the removedUser_, as it is not used again, (unless the
        /// removedUser_ buys in the presale again in the future, in which case the slot mapping will be updated).
        airdropSlot[lastUser_] = slot_; 
    }


    function _beforeTokenTransfer(
        address _idoBuyer,
        uint256 _amountTokensToTransfer,
        uint256 _tradingPhase
    ) private {
        require(_tradingPhase >= 3, "Whitelist IDO phase is not yet active");
        /// Don't limit selling or LP creation during IDO
        if (_idoBuyer != LFJ_V1_PAIR_ADDRESS) {
            /// Track total amount of tokens user receives during the whitelist phase
            userTokensFromWL[_idoBuyer] += _amountTokensToTransfer;
            uint256 _amountPresaleTokensPurchased = presaleTokensPurchased(_idoBuyer);
            require(
                userTokensFromWL[_idoBuyer] <= _amountPresaleTokensPurchased,
                "Cannot receive more tokens than purchased in the presale during WL phase"
            );
        }
    }


    /**
     * @dev Internal helper for user to buy presale tokens.
     * @param _avaxSpent Amount of AVAX user is sending in.
     * @param _presaleBuyer Address of the presale buyer.
     * Reverts if presale ended or minimum AVAX buy amount not received .
     */
    function _buyPresale(uint256 _avaxSpent, address _presaleBuyer) private nonReentrant notSeeded {
        require(block.timestamp < PRESALE_END_TIME, "Presale has already ended");
        require(_avaxSpent >= MINIMUM_BUY, "Minimum buy of 1 AVAX per transaction; Not enough AVAX sent");
        /// Add buyer to the presaleBuyers array, if they are a first time buyer
        if (!previousBuyer[_presaleBuyer]) {
            previousBuyer[_presaleBuyer] = true;
            presaleBuyers.push(_presaleBuyer);
            airdropSlot[_presaleBuyer] = presaleBuyers.length - 1;
            emit BuyerAdded(_presaleBuyer);
        }
        totalAvaxUserSent[_presaleBuyer] += _avaxSpent;
        totalAvaxPresale += _avaxSpent;
        emit PresaleBought(_presaleBuyer, _avaxSpent);
    }


    /**
     * @dev Internal helper airdrop function to process up to `_maxTransfers` recipients from `presaleBuyers`.
     */
    function _airdrop(uint256 _maxTransfers) private {
        uint256 _limitCount = airdropIndex + _maxTransfers;
        address _recipient;
        uint256 _tokensToAirdrop;
        uint256 _localIndex;
        while (airdropIndex < presaleBuyers.length && airdropIndex < _limitCount) {
            _localIndex = airdropIndex;
            airdropIndex++;
            _recipient = presaleBuyers[_localIndex];
            require(!userHasClaimed[_recipient], "User has already received their BRO tokens");
            userHasClaimed[_recipient] = true;
            /// Note we cannot precalculate and save this value, as we don't know the total AVAX until presale ends
            /// Also if we did save the value that would cost more gas than calculating it here on the fly
            /// Calculate _tokensToAirdrop here, instead of with the time checked presaleTokensPurchased(), to save gas
            _tokensToAirdrop = (totalAvaxUserSent[_recipient] * PRESALERS_BRO_SUPPLY) / totalAvaxPresale;
            _transfer(address(this), _recipient, _tokensToAirdrop);
            emit TokensClaimed(_recipient, _tokensToAirdrop);
        }
        if (airdropIndex >= presaleBuyers.length) {
            airdropCompleted = true;
            /// Send any leftover token dust to the last claimant
            sendDust(_recipient);
            emit AirdropCompleted(msg.sender);
        }
    }


    /**
     * @dev Due to the nature of the division in calculations, any leftover token dust is sent to last claimant.
     * @param _lastClaimant Address who receives the final dust remainder.
     */
    function sendDust(address _lastClaimant) private {
        uint256 _dust = balanceOf(address(this));
        _transfer(address(this), _lastClaimant, _dust);
        emit DustSent(_lastClaimant, _dust);
    }


}



/** Legal Disclaimer: 
* My Bro (BRO) is a meme coin (also known as a community token) created for entertainment purposes only. 
* It holds no intrinsic value and should not be viewed as an investment opportunity or a financial instrument.
* It is not a security, as it promises no financial returns to buyers, 
* and does not rely solely on the efforts of the creators and developers.
*
* There is no formal development team behind BRO, and it lacks a structured roadmap. 
* Users should understand the project is experimental and may undergo changes or discontinuation without prior notice.
*
* BRO serves as a platform for the community to engage in activities,
* such as liquidity provision and token swapping on the Avalanche blockchain. 
* It aims to foster community engagement and collaboration, 
* allowing users to participate in activities that may impact the value of their respective tokens.
*
* The value of BRO and associated community tokens may be subject to significant volatility and speculative trading. 
* Users should exercise caution and conduct their own research before engaging with BRO or related activities.
*
* Participation in BRO related activities should not be solely reliant on the actions or guidance of developers. 
* Users are encouraged to take personal responsibility for their involvement and decisions within the BRO ecosystem.
*
* By interacting with BRO or participating in its associated activities, 
* users acknowledge and accept the inherent risks involved,
* and agree to hold harmless the creators and developers of BRO from any liabilities or losses incurred.
*/


/**
* Launch instructions:
* 1. Set the constant values at the start of the contract and the token name and symbol.
* 2. Deploy contract with solidity version: 0.8.28 and runs optimized: 200.
* 3. Verify contract and set socials on block explorer and https://dexscreener.com/ .
* 4. Bug bounty could be good to set up on https://www.sherlock.xyz/ or https://code4rena.com/ or similar.
* 5. After presale ends, call seedLP() in presale contract to create LP.
* 6. Call airdropBuyers() repeatedly in the presale contract to send out all the airdrop tokens to presale buyers.
*/
