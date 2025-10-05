import './styles.scss'
document.addEventListener 'DOMContentLoaded', ->
    form = document.getElementById 'main-form'
    yInput = document.getElementById 'y-input'
    rInput = document.getElementById 'r-input'
    rButtonGroup = document.getElementById 'r-button-group'
    resultsTableBody = document.querySelector '#results-table tbody'
    errorMessageDiv = document.getElementById 'error-message'
    clearButton = document.getElementById 'clear-button'
    dotContainer = document.getElementById 'dot-container'
    xAxisTicks = document.getElementById 'x-axis-ticks'
    yAxisTicks = document.getElementById 'y-axis-ticks'

    svgNamespace = "http://www.w3.org/2000/svg"
    SVG_R_UNIT = 100
    RESULTS_STORAGE_KEY = 'weblab_results_history'

    addResultToTable = (data) ->
        newRow = resultsTableBody.insertRow 0
        hitResultText = if data.hit then 'Попадание' else 'Промах'
        newRow.className = if data.hit then 'hit-true' else 'hit-false'
        newRow.innerHTML = """
            <td>#{parseFloat(data.x).toFixed 2}</td>
            <td>#{parseFloat(data.y).toFixed 2}</td>
            <td>#{parseFloat(data.r).toFixed 2}</td>
            <td>#{hitResultText}</td>
            <td>#{data.currentTime}</td>
            <td>#{parseFloat(data.executionTime).toFixed 4}</td>
        """

    saveResultsToStorage = (results) ->
        localStorage.setItem RESULTS_STORAGE_KEY, JSON.stringify results

    loadResultsFromStorage = ->
        savedResults = localStorage.getItem RESULTS_STORAGE_KEY
        if savedResults then JSON.parse(savedResults) else []

    submitRequest = (formData) ->
        try
            response = await fetch '/calculate',
                method: 'POST'
                body: new URLSearchParams formData

            data = await response.json()
            unless response.ok
                throw new Error data.error or "HTTP error! Status: #{response.status}"

            addResultToTable data

            results = loadResultsFromStorage()
            results.unshift data
            saveResultsToStorage results

            drawPoint data.x, data.y, data.r, data.hit

        catch error
            console.error 'Fetch error:', error
            errorMessageDiv.textContent = "Ошибка: #{error.message}"

    initializePage = ->
        results = loadResultsFromStorage()
        for i in [results.length - 1..0] by -1
            addResultToTable results[i]

        urlParams = new URLSearchParams window.location.search
        x = urlParams.get 'x'
        y = urlParams.get 'y'
        r = urlParams.get 'r'

        if x and y and r
            xRadio = form.querySelector "input[name=\"x\"][value=\"#{x}\"]"
            xRadio.checked = true if xRadio
            yInput.value = y
            rButton = rButtonGroup.querySelector ".r-button[data-value=\"#{r}\"]"
            rButton.click() if rButton
        else
            defaultRButton = document.querySelector '.r-button[data-value="2"]'
            defaultRButton.click() if defaultRButton

    form.addEventListener 'submit', (event) ->
        event.preventDefault()
        errorMessageDiv.textContent = ''
        selectedX = form.querySelector 'input[name="x"]:checked'
        yValueRaw = yInput.value.trim().replace ',', '.'
        yValue = parseFloat yValueRaw
        rValue = rInput.value

        unless selectedX and yValueRaw isnt '' and not isNaN(yValue) and yValue > -3 and yValue < 5 and rValue
            unless selectedX
                errorMessageDiv.textContent = 'Пожалуйста, выберите значение X.'
            else if yValueRaw is '' or isNaN(yValue) or yValue <= -3 or yValue >= 5
                errorMessageDiv.textContent = 'Y должен быть числом в интервале (-3 ... 5).'
            else unless rValue
                errorMessageDiv.textContent = 'Пожалуйста, выберите значение R.'
            return

        formData = new FormData form
        formData.set 'y', yValue.toString()
        submitRequest formData

    rButtonGroup.addEventListener 'click', (event) ->
        if event.target.classList.contains 'r-button'
            rValue = event.target.dataset.value
            rInput.value = rValue
            document.querySelectorAll('.r-button').forEach (btn) -> btn.classList.remove 'selected'
            event.target.classList.add 'selected'
            updateGraphLabels parseFloat rValue

    clearButton.addEventListener 'click', ->
        resultsTableBody.innerHTML = ''
        dotContainer.innerHTML = ''
        localStorage.removeItem RESULTS_STORAGE_KEY
        history.replaceState null, '', window.location.pathname

    updateGraphLabels = (r) ->
        return unless r and not isNaN r
        labels =
            "R": r
            "R/2": r / 2
            "-R/2": -r / 2
            "-R": -r

        xAxisTicks.innerHTML = ''
        yAxisTicks.innerHTML = ''

        for key, value of labels
            svgX = (value / r) * SVG_R_UNIT
            textX = document.createElementNS svgNamespace, 'text'
            textX.setAttribute 'x', svgX
            textX.setAttribute 'y', 15
            textX.textContent = key
            xAxisTicks.appendChild textX

            tickX = document.createElementNS svgNamespace, 'line'
            tickX.setAttribute 'class', 'tick-line'
            tickX.setAttribute 'x1', svgX
            tickX.setAttribute 'y1', -5
            tickX.setAttribute 'x2', svgX
            tickX.setAttribute 'y2', 5
            xAxisTicks.appendChild tickX

            svgY = (-value / r) * SVG_R_UNIT
            textY = document.createElementNS svgNamespace, 'text'
            textY.setAttribute 'x', -10
            textY.setAttribute 'y', svgY + 3
            textY.textContent = key
            yAxisTicks.appendChild textY

            tickY = document.createElementNS svgNamespace, 'line'
            tickY.setAttribute 'class', 'tick-line'
            tickY.setAttribute 'x1', -5
            tickY.setAttribute 'y1', svgY
            tickY.setAttribute 'x2', 5
            tickY.setAttribute 'y2', svgY
            yAxisTicks.appendChild tickY

    drawPoint = (x, y, r, hit) ->
        dotContainer.innerHTML = ''
        return if r <= 0
        svgX = (x / r) * SVG_R_UNIT
        svgY = (-y / r) * SVG_R_UNIT
        dot = document.createElementNS svgNamespace, 'circle'
        dot.setAttribute 'id', 'result-dot'
        dot.setAttribute 'cx', svgX
        dot.setAttribute 'cy', svgY
        dot.setAttribute 'r', 4
        dot.style.fill = if hit then '#198754' else '#dc3545'
        dot.style.stroke = '#fff'
        dot.style.strokeWidth = '1.5'
        dotContainer.appendChild dot

    initializePage()