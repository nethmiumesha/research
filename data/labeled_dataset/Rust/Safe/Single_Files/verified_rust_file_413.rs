use anchor_lang::prelude::*;
use std::cmp::Ordering;
declare_id!("FTeQEfu9uunWyM9EkETP2eJFaeSYY98UE8Y99Ma9zko8");
#[program]
pub mod flutter_vote {
    use super::*;
    pub fn initialize(ctx: Context<Initialize>, name: String, description: String, options: Vec<String>) -> Result<()> {
        ctx.accounts.poll.init(name, description, options)
    }
    pub fn vote(ctx: Context<Vote>, vote_id: u8) -> Result<()> {
        ctx.accounts.poll.vote(vote_id, ctx.accounts.voter.key())
    }
}
#[derive(Clone, AnchorSerialize, AnchorDeserialize)]
pub struct PollOption {
    pub label: String,
    pub id: u8,
    pub votes: u32,
}
#[account]
pub struct Poll {
    pub finished: bool,
    pub name: String,
    pub description: String,
    pub options: Vec<PollOption>,
    pub voters: Vec<Pubkey>,
}
impl Poll {
    pub const MAXIMUM_SIZE: usize = 2170;
    pub fn init(&mut self, name: String, description: String, options: Vec<String>) -> Result<()> {
        require_eq!(self.finished, false, FlutterVoteError::PollAlreadyFinished);
        require!(name.len() <= 50, FlutterVoteError::NameTooLong);
        require!(description.len() <= 200, FlutterVoteError::DescriptionTooLong);
        require!(options.len() <= 5, FlutterVoteError::TooManyOptions);
        let mut c = 0;
        self.name = name;
        self.description = description;
        self.options = options
            .into_iter()
            .map(|option| {
                c += 1;
                PollOption {
                    label: option,
                    id: c,
                    votes: 0,
                }
            })
            .collect();
        self.finished = false;
        Ok(())
    }
    pub fn vote(&mut self, vote_id: u8, voter_key: Pubkey) -> Result<()> {
        require_eq!(self.finished, false, FlutterVoteError::PollAlreadyFinished);
        require_eq!(
            self.options.iter().filter(|option| option.id == vote_id).count(),
            1,
            FlutterVoteError::PollOptionNotFound
        );
        require_eq!(
            self.voters.iter().filter(|voter| **voter == voter_key).count(),
            0,
            FlutterVoteError::UserAlreadyVoted
        );
        self.voters.push(voter_key);
        for option in self.options.iter_mut() {
            if option.id == vote_id {
                option.votes += 1;
            }
        }
        Ok(())
    }
}
#[error_code]
pub enum FlutterVoteError {
    #[msg("Poll is already finished")]
    PollAlreadyFinished,
    #[msg("Poll option not found")]
    PollOptionNotFound,
    #[msg("User has already voted")]
    UserAlreadyVoted,
    #[msg("Poll name exceeds 50 characters")]
    NameTooLong,
    #[msg("Poll description exceeds 200 characters")]
    DescriptionTooLong,
    #[msg("Too many options provided (max 5)")]
    TooManyOptions,
}
#[derive(Accounts)]
pub struct Initialize<'info> {
    #[account(init, payer = owner, space = 8 + Poll::MAXIMUM_SIZE)]
    pub poll: Account<'info, Poll>,
    #[account(mut)]
    pub owner: Signer<'info>,
    pub system_program: Program<'info, System>,
}
#[derive(Accounts)]
pub struct Vote<'info> {
    #[account(mut)]
    pub poll: Account<'info, Poll>,
    #[account(mut)]
    pub voter: Signer<'info>,
}