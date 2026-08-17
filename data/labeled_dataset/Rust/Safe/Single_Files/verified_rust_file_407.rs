#[dependencies]
solana-program = { version = "1.9.3" }
spl-token = { version = "3.3.2" , features = ["fixed-point"] }
use solana_program::program::Program;
#[account]
#[derive(Default)]
pub struct Mint {
    pub supply: u64,
    pub mint_authority: Option<Pubkey>,
    pub freeze_authority: Option<Pubkey>,
    pub decimal_places: u8,
    pub is_mutable: bool,
    pub custodian_option: Option<CustodianOption>,
    pub reserve: Option<Reserve>,
}
use anchor_lang::prelude::*;
declare_id!("Bx9zQCi2Tm4X2mYZSjJtCyAnKs1e2ywfMB1FgCaEdGzX");
#[program]
pub mod vehicular_control {
    use anchor_lang::solana_program::rent::Rent;
    pub fn create_nft(
        ctx: Context<CreateNftContext>,
        name: String,
        image_url: String,
    ) -> Result<()> {
        let mint_account = &mut ctx.accounts.mint;
        let rent = &ctx.rent;
        let account_size = Mint::MAX_ACCOUNT_SIZE;
        let rent_lamports = rent.rent(account_size);
        ctx.accounts.user.transfer(rent_lamports, ctx.accounts.system_program)?;
        spl_token::instruction::initialize_mint(
            &mut ctx.accounts.mint.to_account_info(),
            &ctx.accounts.authority.to_account_info(),
            &ctx.accounts.payer.to_account_info(),
            decimals,
            true,
        )?;
        spl_token::instruction::create_account(
            &mut ctx.accounts.token_account.to_account_info(),
            &ctx.accounts.mint.to_account_info(),
            &ctx.accounts.authority.to_account_info(),
            &ctx.accounts.payer.to_account_info(),
        )?;
        spl_token::instruction::mint_to(
            &mut ctx.accounts.mint.to_account_info(),
            &ctx.accounts.token_account.to_account_info(),
            &ctx.accounts.authority.to_account_info(),
            &ctx.accounts.payer.to_account_info(),
            1,
        )?;
        msg!("NFT creado exitosamente!");
        Ok(())
    }
}
#[derive(Accounts)]
pub struct CreateNftContext {
    #[account(init, system_program)]
    pub mint: AccountInfo<'static>,
    #[account(mut)]
    pub user: Signer,
    #[account(system_program)]
    pub system_program: AccountInfo<'static>,
    #[account(executable = Rent::default().program)]
    pub rent: AccountInfo<'static>,
    #[account(payer)]
    pub payer: Signer,
    #[account(init, mint::authority = authority)]
    pub token_account: AccountInfo<'static>,
    pub authority: Signer,
}
pub enum CustodianOption {
    Custodian(Pubkey),
    None,
}
#[account]
#[derive(Default)]
pub struct Mint {
    pub supply: u64,
    pub mint_authority: Option<Pubkey>,
    pub freeze_authority: Option<Pubkey>,
    pub decimal_places: u8,
    pub is_mutable: bool,
    pub custodian_option: Option<CustodianOption>,
    pub reserve: Option<Reserve>,
}