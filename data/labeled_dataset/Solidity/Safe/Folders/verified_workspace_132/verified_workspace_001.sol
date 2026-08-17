pragma solidity ^0.8.0;
import "./modules/kap20/interfaces/IKAP20.sol";
import "./modules/kap20/interfaces/IKToken.sol";
import "./modules/erc20/interfaces/IEIP20NonStandard.sol";
import "./interfaces/IInterestRateModel.sol";
import "./interfaces/ILKAP20.sol";
import "./abstracts/LendingContract.sol";
contract KAP20Lending is LendingContract {
    constructor(
        address underlyingToken_,
        address controller_,
        address interestRateModel_,
        uint256 initialExchangeRateMantissa_,
        string memory lTokenName_,
        string memory lTokenSymbol_,
        uint8 lTokenDecimals_,
        address committee_,
        address adminRouter_,
        address kyc_,
        uint256 acceptedKycLevel_
    )
        LendingContract(
            controller_,
            interestRateModel_,
            initialExchangeRateMantissa_,
            lTokenName_,
            lTokenSymbol_,
            lTokenDecimals_,
            committee_,
            adminRouter_,
            kyc_,
            acceptedKycLevel_
        )
    {
        underlyingToken = underlyingToken_;
        IKAP20(underlyingToken).totalSupply();
    }
    function deposit(uint256 depositAmount, address sender)
        external
        returns (uint256)
    {
        uint256 err;
        if (adminRouter.isSuperAdmin(msg.sender, PROJECT)) {
            requireKYC(sender);
            (err, ) = depositInternal(
                sender,
                depositAmount,
                TransferMethod.BK_NEXT
            );
        } else {
            (err, ) = depositInternal(
                msg.sender,
                depositAmount,
                TransferMethod.METAMASK
            );
        }
        return err;
    }
    function withdraw(uint256 withdrawTokens, address payable sender)
        external
        returns (uint256)
    {
        uint256 err;
        if (adminRouter.isSuperAdmin(msg.sender, PROJECT)) {
            requireKYC(sender);
            err = withdrawInternal(sender, withdrawTokens, TransferMethod.BK_NEXT);
        } else {
            err = withdrawInternal(payable(msg.sender), withdrawTokens, TransferMethod.METAMASK);
        }
        return err;
    }
    function withdrawUnderlying(uint256 withdrawAmount, address payable sender)
        external
        returns (uint256)
    {
        uint256 err;
        if (adminRouter.isSuperAdmin(msg.sender, PROJECT)) {
            requireKYC(sender);
            err = withdrawUnderlyingInternal(sender, withdrawAmount, TransferMethod.BK_NEXT);
        } else {
            err = withdrawUnderlyingInternal(
                payable(msg.sender),
                withdrawAmount,
                TransferMethod.METAMASK
            );
        }
        return err;
    }
    function borrow(uint256 borrowAmount, address payable sender)
        external
        returns (uint256)
    {
        uint256 err;
        if (adminRouter.isSuperAdmin(msg.sender, PROJECT)) {
            requireKYC(sender);
            err = borrowInternal(sender, borrowAmount, TransferMethod.BK_NEXT);
        } else {
            err = borrowInternal(payable(msg.sender), borrowAmount, TransferMethod.METAMASK);
        }
        return err;
    }
    function repayBorrow(uint256 repayAmount, address sender)
        external
        returns (uint256)
    {
        uint256 err;
        if (adminRouter.isSuperAdmin(msg.sender, PROJECT)) {
            requireKYC(sender);
            (err, ) = repayBorrowInternal(
                sender,
                repayAmount,
                TransferMethod.BK_NEXT
            );
        } else {
            (err, ) = repayBorrowInternal(
                msg.sender,
                repayAmount,
                TransferMethod.METAMASK
            );
        }
        return err;
    }
    function repayBorrowBehalf(
        address borrower,
        uint256 repayAmount,
        address sender
    ) external returns (uint256) {
        uint256 err;
        if (adminRouter.isSuperAdmin(msg.sender, PROJECT)) {
            requireKYC(sender);
            (err, ) = repayBorrowBehalfInternal(
                sender,
                borrower,
                repayAmount,
                TransferMethod.BK_NEXT
            );
        } else {
            (err, ) = repayBorrowBehalfInternal(
                msg.sender,
                borrower,
                repayAmount,
                TransferMethod.METAMASK
            );
        }
        return err;
    }
    function liquidateBorrow(address borrower, address payable sender)
        external
        returns (uint256)
    {
        uint256 err;
        if (adminRouter.isSuperAdmin(msg.sender, PROJECT)) {
            requireKYC(sender);
            (err, ) = liquidateBorrowInternal(sender, borrower, TransferMethod.BK_NEXT);
        } else {
            (err, ) = liquidateBorrowInternal(payable(msg.sender), borrower, TransferMethod.METAMASK);
        }
        return err;
    }
    function sweepToken(IEIP20NonStandard token) external onlyAdmin {
        require(
            address(token) != underlyingToken,
            "Can not sweep underlying token"
        );
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }
    function getCashPrior() internal view override returns (uint256) {
        return IKAP20(underlyingToken).balanceOf(address(this));
    }
    function doTransferIn(
        address from,
        uint256 amount,
        TransferMethod method
    ) internal override returns (uint256) {
        if (method == TransferMethod.BK_NEXT) {
            return doTransferInBKNext(from, amount);
        } else {
            return doTransferInMetamask(from, amount);
        }
    }
    function doTransferInBKNext(address from, uint256 amount)
        private
        returns (uint256)
    {
        IKAP20 token = IKAP20(underlyingToken);
        uint256 balanceBefore = token.balanceOf(address(this));
        IKToken(underlyingToken).externalTransfer(from, address(this), amount);
        uint256 balanceAfter = token.balanceOf(address(this));
        require(balanceAfter >= balanceBefore, "Transfer in overflow");
        return balanceAfter - balanceBefore;
    }
    function doTransferInMetamask(address from, uint256 amount)
        private
        returns (uint256)
    {
        IEIP20NonStandard token = IEIP20NonStandard(underlyingToken);
        uint256 balanceBefore = IKAP20(underlyingToken).balanceOf(
            address(this)
        );
        token.transferFrom(from, address(this), amount);
        bool success;
        assembly {
            switch returndatasize()
            case 0 {
                success := not(0)
            }
            case 32 {
                returndatacopy(0, 0, 32)
                success := mload(0)
            }
            default {
                revert(0, 0)
            }
        }
        require(success, "Transfer in failed");
        uint256 balanceAfter = IKAP20(underlyingToken).balanceOf(address(this));
        require(balanceAfter >= balanceBefore, "Transfer in overflow");
        return balanceAfter - balanceBefore;
    }
    function doTransferOut(address payable to, uint256 amount, TransferMethod method)
        internal
        override
    {
        method;
        IEIP20NonStandard token = IEIP20NonStandard(underlyingToken);
        token.transfer(to, amount);
        bool success;
        assembly {
            switch returndatasize()
            case 0 {
                success := not(0)
            }
            case 32 {
                returndatacopy(0, 0, 32)
                success := mload(0)
            }
            default {
                revert(0, 0)
            }
        }
        require(success, "Transfer out failed");
    }
}