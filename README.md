# RAM: Read-First / No-Change

## Overview

SystemVerilog로 구현한 256 x 16-bit Single-Port Synchronous RAM 설계임. 동일한 주소에서 read와 write가 발생할 때의 출력 방식에 따라 Read-First와 No-Change 두 가지 RAM 동작을 구현함.

각 RAM 설계는 UVM testbench를 통해 read/write 동작, 동일 주소 접근 및 출력 데이터 유지 동작을 검증함.

## Specifications

- 256-word memory depth
- 16비트 data width
- 8비트 address
- Single-port synchronous read/write
- Read-First RAM 동작
- No-Change RAM 동작
- UVM sequence 기반 random transaction
- Reference memory 기반 Scoreboard
- Read/write, address 및 write data Functional Coverage

## RAM Interface

Read-First와 No-Change RAM은 동일한 interface를 사용함.

| 신호 | 방향 | 폭 | 설명 |
| --- | --- | --- | --- |
| `clk` | Input | 1 | 동작 클럭 |
| `we` | Input | 1 | Write enable |
| `addr` | Input | 8 | Read/write address |
| `wdata` | Input | 16 | Write data |
| `rdata` | Output | 16 | Read data |

메모리는 256개의 16비트 word로 구성함.

```systemverilog
logic [15:0] mem [0:255];
```

## Read-First RAM

`RAM_read_first/RAM.sv`에서 Read-First 방식의 RAM을 구현함.

Write cycle에서 기존 address의 데이터를 `rdata`로 출력한 후 새로운 `wdata`를 memory에 저장함. Non-blocking assignment 특성에 따라 동일 clock edge에서 기존 memory 값이 먼저 출력됨.

```systemverilog
always_ff @(posedge clk) begin
    if (we) begin
        mem[addr] <= wdata;
    end
    rdata <= mem[addr];
end
```

Read-First testbench는 `RAM_read_first/tb_RAM.sv`에 UVM 구성요소를 하나의 파일로 구성함. `ram_test`에서 1,000개의 random transaction을 생성하고 reference memory와 DUT 출력을 비교함.

## No-Change RAM

`RAM_no_change/rtl/ram.sv`에서 No-Change 방식의 RAM을 구현함.

Write cycle에서는 memory 값만 갱신하고 `rdata`는 이전 출력값을 유지함. `we`가 비활성화된 read cycle에서만 지정한 address의 memory 값을 출력함.

```systemverilog
always_ff @(posedge clk) begin
    if (we) begin
        mem[addr] <= wdata;
    end else begin
        rdata <= mem[addr];
    end
end
```

## UVM Architecture

No-Change RAM testbench는 기능별 UVM component를 개별 파일로 구성함.

Driver는 negedge clocking block을 통해 `we`, `addr`, `wdata`를 DUT에 입력함. Monitor는 RAM transaction과 `rdata`를 수집하여 Scoreboard와 Coverage에 전달함.

Scoreboard는 256 x 16-bit reference memory를 유지함. Read cycle에서는 선택한 address의 reference data와 `rdata`를 비교하고, Write cycle에서는 이전 `rdata`가 유지되는지 확인한 후 reference memory를 갱신함.

## Verification

### Read-First Test

| Test | Transaction | 검증 내용 |
| --- | --- | --- |
| `ram_test` | 1,000 | Random read/write 및 Read-First 출력 |

### No-Change Test

| Test | Transaction | 검증 내용 |
| --- | --- | --- |
| `ram_test` | 100 | Random read/write 및 No-Change 출력 |
| `ram_test_2` | 100회 반복 | 동일 address의 read -> write -> read 동작 |

### Functional Coverage

| Coverpoint | 검증 범위 |
| --- | --- |
| `cp_we` | Read 및 Write |
| `cp_addr` | `0-63`, `64-127`, `128-191`, `192-255` |
| `cp_wdata` | 16비트 write data |
| `cx_we_addr` | Read/Write와 address 영역 조합 |

## Verification Results

Read-First RAM은 random read/write transaction으로 검증함. No-Change RAM은 random read/write와 동일 address의 `read -> write -> read` 조건으로 검증함.

| 검증 대상 | Test | 결과 | Coverage |
| --- | --- | --- | --- |
| Read-First RAM | Random R/W Test | Pass | - |
| No-Change RAM | Random R/W 및 Same Address Test | Pass | ≈ 93% |

Scoreboard에서 DUT 출력과 reference memory의 예상값을 비교한 결과, 두 RAM 모두 mismatch 없이 모든 transaction이 정상적으로 일치함.

Read-First RAM은 Write cycle에서 기존 memory data가 `rdata`로 출력되고 새로운 `wdata`가 정상적으로 저장되는 것을 확인함. 별도의 Functional Coverage는 수집하지 않음.

No-Change RAM은 Write cycle에서 `rdata`가 유지되고 Read cycle에서 선택한 address의 data가 정상적으로 출력되는 것을 확인함. Read/Write, address 영역, write data 및 Read/Write와 address 간 Cross Coverage를 수집하여 ≈ 93%의 Functional Coverage를 달성함.

## Directory Structure

```text
RAM/
├── RAM_read_first/
│   ├── RAM.sv
│   └── tb_RAM.sv
└── RAM_no_change/
    ├── rtl/
    │   └── ram.sv
    └── tb/
        ├── tb_ram_top.sv
        ├── ram_uvm_pkg.sv
        ├── ram_interface.sv
        ├── ram_sequence_item.sv
        ├── ram_sequence.sv
        ├── ram_driver.sv
        ├── ram_monitor.sv
        ├── ram_agent.sv
        ├── ram_scoreboard.sv
        ├── ram_coverage.sv
        ├── ram_environment.sv
        └── ram_test.sv
```
