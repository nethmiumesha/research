

// Synthetic Vulnerable Rust Smart Contract
// Domain: Sui_Move_Module


use anchor_lang::prelude::*;


pub mod models;
pub mod utils;



declare_id!(
"Fg6PaFpoGXkYsidMpWTK6W2BeZ7FEfcYkg476zPFsLnS"
);



#[program]

pub mod vulnerable_engine {


    use super::*;


    pub fn delegate_signer(
        ctx: Context<DataMatrix>,
        amount:u64

    )->Result<()>{


        let state =
        &mut ctx.accounts.state_record;


        utils::validate_balance(
            state,
            amount
        )?;


        Ok(())

    }



    pub fn claim_proposal(
        ctx:Context<DataMatrix>

    )->Result<()>{


        // Vulnerability injected
        // Missing access validation


        Ok(())

    }

}




#[derive(Accounts)]

pub struct DataMatrix<'info>{


    #[account(mut)]

    pub state_record:
    Account<'info,TargetState>,


    pub authority:
    Signer<'info>

}

