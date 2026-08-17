use anchor_lang::prelude::*;
#[error_code]
pub enum AuctioneerError {
    #[msg("Bump seed not in hash map")]
    BumpSeedNotInHashMap,
    #[msg("Auction has not started yet")]
    AuctionNotStarted,
    #[msg("Auction has ended")]
    AuctionEnded,
    #[msg("Auction has not ended yet")]
    AuctionActive,
    #[msg("The bid was lower than the highest bid")]
    BidTooLow,
    #[msg("The signer must be the Auction House authority")]
    SignerNotAuth,
    #[msg("Execute Sale must be run on the highest bidder")]
    NotHighestBidder,
    #[msg("The bid price must be greater than the reserve price")]
    BelowReservePrice,
    #[msg("The bid must match the highest bid plus the minimum bid increment")]
    BelowBidIncrement,
    #[msg("The highest bidder is not allowed to cancel")]
    CannotCancelHighestBid,
}