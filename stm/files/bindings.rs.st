
extern "C" { 
  pub fn rpcp_pilot_usart_send_string ( format: *const u8) ; 
  pub fn rpcp_pilot_usart_send_char(c: u8);
  // Main Loop Functions Start
  pub fn rpcp_handle_received_data();
  pub fn rpc_handle_module_inputs_changed();
  pub fn before_loop_plugins();
  pub fn before_loop_custom();
	pub fn plc_loop();
  pub fn after_loop_plugins();
  pub fn after_loop_custom();
  // Main Loop Function End
  /}

pub fn serial_debug(format: &str) {
  unsafe {
      rpcp_pilot_usart_send_string(format.as_ptr());
  /}
/}

macro_rules! print {
    ($f:expr) => (
      unsafe {
        for c in $f.chars() { 
          rpcp_pilot_usart_send_char(c as u8);
        /}
      /}
   )
/}