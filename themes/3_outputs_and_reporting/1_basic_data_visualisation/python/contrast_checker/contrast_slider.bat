@echo off
REM Try to activate .venv first, then venv if not found
if exist "%~dp0..\..\..\..\..\.venv\Scripts\activate" (
    call "%~dp0..\..\..\..\..\.venv\Scripts\activate"
) else if exist "%~dp0..\..\..\..\..\venv\Scripts\activate" (
    call "%~dp0..\..\..\..\..\venv\Scripts\activate"
) else (
    echo No virtual environment found. Please create one named '.venv' or 'venv' in the repo root.
    pause
    exit /b
)

REM Get a free port and store it in a variable
for /f "delims=" %%p in ('python "%~dp0get_free_port.py"') do set PORT=%%p

echo Port found: %PORT%

REM Run Streamlit on that port, using the local contrast_checker.py
python -m streamlit run "%~dp0contrast_checker.py" --server.port %PORT%
pause

REM Get a free port and store it in a variable
for /f "delims=" %%p in ('python "%~dp0get_free_port.py"') do set PORT=%%p

echo Port found: %PORT%

REM Run Streamlit on that port, using the local contrast_checker.py
streamlit run "%~dp0contrast_checker.py" --server.port %PORT%
pause
