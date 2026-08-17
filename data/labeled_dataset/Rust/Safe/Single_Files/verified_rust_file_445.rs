use anchor_lang::prelude::*;
#[derive(AnchorSerialize, AnchorDeserialize, Clone, Debug)]
pub struct X402PaymentRequest {
    pub recipient: Pubkey,
    pub amount: u64,
    pub asset: u8,
    pub payment_id: [u8; 32],
    pub expires_at: i64,
    pub callback_url_hash: [u8; 32],
}
impl X402PaymentRequest {
    pub fn is_valid(&self, current_time: i64) -> bool {
        current_time < self.expires_at && self.amount > 0
    }
}
#[account]
#[derive(InitSpace)]
pub struct X402Receipt {
    pub payment_id: [u8; 32],
    pub payer: Pubkey,
    pub recipient: Pubkey,
    pub amount: u64,
    pub paid_at: i64,
    pub tx_signature: [u8; 64],
    pub bump: u8,
}
#[derive(AnchorSerialize, AnchorDeserialize, Clone, Copy, Default, InitSpace)]
pub struct X402Stats {
    pub total_payments: u64,
    pub total_amount_paid: u64,
    pub total_borrowed_for_x402: u64,
    pub last_payment_at: i64,
}
pub fn verify_x402_request(request: &X402PaymentRequest, _signature: &[u8]) -> bool {
    request.amount > 0 && request.amount < 1_000_000_000_000
}