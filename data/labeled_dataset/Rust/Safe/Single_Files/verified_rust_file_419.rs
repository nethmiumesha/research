extern crate proc_macro;
use {
    anchor_syn::{
        codegen,
        parser::error::{self as error_parser, ErrorInput},
        ErrorArgs,
    },
    proc_macro::TokenStream,
    quote::quote,
    syn::{parse_macro_input, Expr},
};
#[proc_macro_attribute]
pub fn error_code(
    args: proc_macro::TokenStream,
    input: proc_macro::TokenStream,
) -> proc_macro::TokenStream {
    let args = match args.is_empty() {
        true => None,
        false => Some(parse_macro_input!(args as ErrorArgs)),
    };
    let mut error_enum = parse_macro_input!(input as syn::ItemEnum);
    let error = codegen::error::generate(error_parser::parse(&mut error_enum, args));
    proc_macro::TokenStream::from(error)
}
#[proc_macro]
pub fn error(ts: proc_macro::TokenStream) -> TokenStream {
    let input = parse_macro_input!(ts as ErrorInput);
    let error_code = input.error_code;
    create_error(error_code, true, None)
}
fn create_error(error_code: Expr, source: bool, account_name: Option<Expr>) -> TokenStream {
    let error_origin = match (source, account_name) {
        (false, None) => quote! { None },
        (false, Some(account_name)) => quote! {
            Some(anchor_lang::error::ErrorOrigin::AccountName(#account_name.to_string()))
        },
        (true, _) => quote! {
            Some(anchor_lang::error::ErrorOrigin::Source(anchor_lang::error::Source {
                filename: file!(),
                line: line!()
            }))
        },
    };
    TokenStream::from(quote! {
        anchor_lang::error::Error::from(
            anchor_lang::error::AnchorError {
                error_name: #error_code.name(),
                error_code_number: #error_code.into(),
                error_msg: #error_code.to_string(),
                error_origin: #error_origin,
                compared_values: None
            }
        )
    })
}