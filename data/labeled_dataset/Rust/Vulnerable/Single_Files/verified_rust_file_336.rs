

// Synthetic Vulnerable Rust Smart Contract
// Domain: CosmWasm_Contract


use anchor_lang::prelude::*;


pub mod models;
pub mod utils;



declare_id!(
"Fg6PaFpoGXkYsidMpWTK6W2BeZ7FEfcYkg476zPFsLnS"
);



#[program]

pub mod vulnerable_engine {


    use super::*;


    pub fn execute_state(
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



    pub fn burn_vault(
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

