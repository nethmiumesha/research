use solana_sdk::instruction::Instruction;
use solana_sdk::pubkey::Pubkey;
use solana_sdk::system_program::ID as SYSTEM_PROGAM_ID;
use solana_sdk::sysvar::{rent::Rent, SysvarId};
use anchor_lang::prelude::{Id, System, ToAccountMetas};
use anchor_lang::InstructionData;
use anchor_spl::token::Token;
use jet_margin::instruction as ix_data;
use jet_margin::program::JetMargin;
use jet_margin::{accounts as ix_account, CompactAccountMeta};
pub struct MarginIxBuilder {
    pub owner: Pubkey,
    pub seed: u16,
    pub payer: Pubkey,
    pub address: Pubkey,
    authority: Option<Pubkey>,
}
impl MarginIxBuilder {
    pub fn new(owner: Pubkey, seed: u16) -> Self {
        Self::new_with_payer(owner, seed, owner)
    }
    pub fn new_with_payer(owner: Pubkey, seed: u16, payer: Pubkey) -> Self {
        let (address, _) = Pubkey::find_program_address(
            &[owner.as_ref(), 0u16.to_le_bytes().as_ref()],
            &jet_margin::ID,
        );
        Self {
            owner,
            seed,
            payer,
            address,
            authority: None,
        }
    }
    pub fn create_account(&self) -> Instruction {
        let accounts = ix_account::CreateAccount {
            owner: self.owner,
            payer: self.payer,
            margin_account: self.address,
            system_program: SYSTEM_PROGAM_ID,
        };
        Instruction {
            program_id: JetMargin::id(),
            data: ix_data::CreateAccount { seed: self.seed }.data(),
            accounts: accounts.to_account_metas(None),
        }
    }
    pub fn close_account(&self) -> Instruction {
        let accounts = ix_account::CloseAccount {
            owner: self.owner,
            receiver: self.payer,
            margin_account: self.address,
        };
        Instruction {
            program_id: JetMargin::id(),
            data: ix_data::CloseAccount.data(),
            accounts: accounts.to_account_metas(None),
        }
    }
    pub fn update_position_balance(&self, account: Pubkey) -> Instruction {
        let accounts = ix_account::UpdatePositionBalance {
            margin_account: self.address,
            token_account: account,
        };
        Instruction {
            program_id: JetMargin::id(),
            data: ix_data::UpdatePositionBalance.data(),
            accounts: accounts.to_account_metas(None),
        }
    }
    pub fn register_position(&self, position_token_mint: Pubkey) -> (Pubkey, Instruction) {
        let (token_account, _) = self.get_token_account_address(&position_token_mint);
        let (metadata, _) =
            Pubkey::find_program_address(&[position_token_mint.as_ref()], &jet_metadata::ID);
        let accounts = ix_account::RegisterPosition {
            authority: self.authority(),
            payer: self.payer,
            margin_account: self.address,
            position_token_mint,
            metadata,
            token_account,
            token_program: Token::id(),
            system_program: System::id(),
            rent: Rent::id(),
        };
        let ix = Instruction {
            program_id: JetMargin::id(),
            data: ix_data::RegisterPosition {}.data(),
            accounts: accounts.to_account_metas(None),
        };
        (token_account, ix)
    }
    pub fn close_position(
        &self,
        position_token_mint: Pubkey,
        token_account: Pubkey,
    ) -> Instruction {
        let accounts = ix_account::ClosePosition {
            authority: self.authority(),
            receiver: self.payer,
            margin_account: self.address,
            position_token_mint,
            token_account,
            token_program: Token::id(),
        };
        Instruction {
            program_id: JetMargin::id(),
            data: ix_data::ClosePosition.data(),
            accounts: accounts.to_account_metas(None),
        }
    }
    pub fn adapter_invoke(&self, adapter_ix: Instruction) -> Instruction {
        invoke!(
            self.address,
            adapter_ix,
            AdapterInvoke { owner: self.owner }
        )
    }
    pub fn accounting_invoke(&self, adapter_ix: Instruction) -> Instruction {
        invoke!(self.address, adapter_ix, AccountingInvoke)
    }
    pub fn liquidate_begin(&self, liquidator: Pubkey) -> Instruction {
        let (liquidator_metadata, _) =
            Pubkey::find_program_address(&[liquidator.as_ref()], &jet_metadata::id());
        let (liquidation, _) = Pubkey::find_program_address(
            &[b"liquidation", self.address.as_ref(), liquidator.as_ref()],
            &jet_margin::id(),
        );
        let accounts = ix_account::LiquidateBegin {
            margin_account: self.address,
            payer: self.payer,
            liquidator,
            liquidator_metadata,
            liquidation,
            system_program: SYSTEM_PROGAM_ID,
        };
        Instruction {
            program_id: JetMargin::id(),
            accounts: accounts.to_account_metas(None),
            data: ix_data::LiquidateBegin {}.data(),
        }
    }
    #[allow(clippy::redundant_field_names)]
    pub fn liquidator_invoke(&self, adapter_ix: Instruction, liquidator: &Pubkey) -> Instruction {
        let (liquidation, _) = Pubkey::find_program_address(
            &[b"liquidation", self.address.as_ref(), liquidator.as_ref()],
            &jet_margin::id(),
        );
        invoke!(
            self.address,
            adapter_ix,
            LiquidatorInvoke {
                liquidator: *liquidator,
                liquidation: liquidation,
            }
        )
    }
    pub fn liquidate_end(
        &self,
        authority: Pubkey,
        original_liquidator: Option<Pubkey>,
    ) -> Instruction {
        let original = original_liquidator.unwrap_or(authority);
        let (liquidation, _) = Pubkey::find_program_address(
            &[b"liquidation", self.address.as_ref(), original.as_ref()],
            &JetMargin::id(),
        );
        let accounts = ix_account::LiquidateEnd {
            margin_account: self.address,
            authority,
            liquidation,
        };
        Instruction {
            program_id: JetMargin::id(),
            accounts: accounts.to_account_metas(None),
            data: ix_data::LiquidateEnd.data(),
        }
    }
    pub fn verify_healthy(&self) -> Instruction {
        let accounts = ix_account::VerifyHealthy {
            margin_account: self.address,
        };
        Instruction {
            program_id: JetMargin::id(),
            accounts: accounts.to_account_metas(None),
            data: ix_data::VerifyHealthy.data(),
        }
    }
    #[inline]
    pub fn get_token_account_address(&self, position_token_mint: &Pubkey) -> (Pubkey, u8) {
        Pubkey::find_program_address(
            &[self.address.as_ref(), position_token_mint.as_ref()],
            &JetMargin::id(),
        )
    }
    fn authority(&self) -> Pubkey {
        match self.authority {
            None => self.owner,
            Some(authority) => authority,
        }
    }
}
macro_rules! invoke {
    (
        $margin_account:expr,
        $adapter_ix:ident,
        $Instruction:ident $({
            $($additional_field:ident: $value:expr),* $(,)?
        })?
    ) => {{
        let (adapter_metadata, _) =
            Pubkey::find_program_address(&[$adapter_ix.program_id.as_ref()], &jet_metadata::ID);
        let mut accounts = ix_account::$Instruction {
            margin_account: $margin_account,
            adapter_program: $adapter_ix.program_id,
            adapter_metadata,
            $(
                $($additional_field: $value),*
            )?
        }
        .to_account_metas(None);
        let adapter_metas = $adapter_ix.accounts.iter().skip(1);
        let compact_account_metas = adapter_metas
            .clone()
            .map(|a| CompactAccountMeta {
                is_signer: if a.is_signer { 1 } else { 0 },
                is_writable: if a.is_writable { 1 } else { 0 },
            })
            .collect();
        accounts.extend(adapter_metas.cloned());
        Instruction {
            program_id: JetMargin::id(),
            data: ix_data::$Instruction {
                data: $adapter_ix.data,
                account_metas: compact_account_metas,
            }
            .data(),
            accounts,
        }
    }};
}
use invoke;