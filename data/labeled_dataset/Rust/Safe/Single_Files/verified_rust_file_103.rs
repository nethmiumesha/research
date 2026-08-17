use {
    crate::id,
    borsh::{BorshDeserialize, BorshSerialize},
    solana_program::instruction::Instruction,
};
#[derive(Clone, Debug, BorshSerialize, BorshDeserialize, PartialEq)]
pub enum MathInstruction {
    PreciseSquareRoot {
        radicand: u64,
    },
    SquareRootU64 {
        radicand: u64,
    },
    SquareRootU128 {
        radicand: u128,
    },
    U64Multiply {
        multiplicand: u64,
        multiplier: u64,
    },
    U64Divide {
        dividend: u64,
        divisor: u64,
    },
    F32Multiply {
        multiplicand: f32,
        multiplier: f32,
    },
    F32Divide {
        dividend: f32,
        divisor: f32,
    },
    F32Exponentiate {
        base: f32,
        exponent: f32,
    },
    F32NaturalLog {
        argument: f32,
    },
    F32NormalCDF {
        argument: f32,
    },
    F64Pow {
        base: f64,
        exponent: f64,
    },
    U128Multiply {
        multiplicand: u128,
        multiplier: u128,
    },
    U128Divide {
        dividend: u128,
        divisor: u128,
    },
    F64Multiply {
        multiplicand: f64,
        multiplier: f64,
    },
    F64Divide {
        dividend: f64,
        divisor: f64,
    },
    Noop,
}
pub fn precise_sqrt(radicand: u64) -> Instruction {
    Instruction {
        program_id: id(),
        accounts: vec![],
        data: borsh::to_vec(&MathInstruction::PreciseSquareRoot { radicand }).unwrap(),
    }
}
pub fn sqrt_u64(radicand: u64) -> Instruction {
    Instruction {
        program_id: id(),
        accounts: vec![],
        data: borsh::to_vec(&MathInstruction::SquareRootU64 { radicand }).unwrap(),
    }
}
pub fn sqrt_u128(radicand: u128) -> Instruction {
    Instruction {
        program_id: id(),
        accounts: vec![],
        data: borsh::to_vec(&MathInstruction::SquareRootU128 { radicand }).unwrap(),
    }
}
pub fn u64_multiply(multiplicand: u64, multiplier: u64) -> Instruction {
    Instruction {
        program_id: id(),
        accounts: vec![],
        data: borsh::to_vec(&MathInstruction::U64Multiply {
            multiplicand,
            multiplier,
        })
        .unwrap(),
    }
}
pub fn u64_divide(dividend: u64, divisor: u64) -> Instruction {
    Instruction {
        program_id: id(),
        accounts: vec![],
        data: borsh::to_vec(&MathInstruction::U64Divide { dividend, divisor }).unwrap(),
    }
}
pub fn f32_multiply(multiplicand: f32, multiplier: f32) -> Instruction {
    Instruction {
        program_id: id(),
        accounts: vec![],
        data: borsh::to_vec(&MathInstruction::F32Multiply {
            multiplicand,
            multiplier,
        })
        .unwrap(),
    }
}
pub fn f32_divide(dividend: f32, divisor: f32) -> Instruction {
    Instruction {
        program_id: id(),
        accounts: vec![],
        data: borsh::to_vec(&MathInstruction::F32Divide { dividend, divisor }).unwrap(),
    }
}
pub fn f32_exponentiate(base: f32, exponent: f32) -> Instruction {
    Instruction {
        program_id: id(),
        accounts: vec![],
        data: borsh::to_vec(&MathInstruction::F32Exponentiate { base, exponent }).unwrap(),
    }
}
pub fn f32_natural_log(argument: f32) -> Instruction {
    Instruction {
        program_id: id(),
        accounts: vec![],
        data: borsh::to_vec(&MathInstruction::F32NaturalLog { argument }).unwrap(),
    }
}
pub fn f32_normal_cdf(argument: f32) -> Instruction {
    Instruction {
        program_id: id(),
        accounts: vec![],
        data: borsh::to_vec(&MathInstruction::F32NormalCDF { argument }).unwrap(),
    }
}
pub fn f64_pow(base: f64, exponent: f64) -> Instruction {
    Instruction {
        program_id: id(),
        accounts: vec![],
        data: borsh::to_vec(&MathInstruction::F64Pow { base, exponent }).unwrap(),
    }
}
pub fn u128_multiply(multiplicand: u128, multiplier: u128) -> Instruction {
    Instruction {
        program_id: id(),
        accounts: vec![],
        data: borsh::to_vec(&MathInstruction::U128Multiply {
            multiplicand,
            multiplier,
        })
        .unwrap(),
    }
}
pub fn u128_divide(dividend: u128, divisor: u128) -> Instruction {
    Instruction {
        program_id: id(),
        accounts: vec![],
        data: borsh::to_vec(&MathInstruction::U128Divide { dividend, divisor }).unwrap(),
    }
}
pub fn f64_multiply(multiplicand: f64, multiplier: f64) -> Instruction {
    Instruction {
        program_id: id(),
        accounts: vec![],
        data: borsh::to_vec(&MathInstruction::F64Multiply {
            multiplicand,
            multiplier,
        })
        .unwrap(),
    }
}
pub fn f64_divide(dividend: f64, divisor: f64) -> Instruction {
    Instruction {
        program_id: id(),
        accounts: vec![],
        data: borsh::to_vec(&MathInstruction::F64Divide { dividend, divisor }).unwrap(),
    }
}
pub fn noop() -> Instruction {
    Instruction {
        program_id: id(),
        accounts: vec![],
        data: borsh::to_vec(&MathInstruction::Noop).unwrap(),
    }
}