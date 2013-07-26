'Represents a simple 2D image carousel. Uses background shadow images for loading purposes.
'@param images an array of image file paths
'@param bigShadow a dictionary specifying parameters of the big shadow to be used. Example: {path: "pkg:/shadow.png", offsetX: 10, offsetY: 10, width: 100, height: 100}
'@param smallShadow a dictionary specifying parameters of the small shadow to be used. Example: {path: "pkg:/shadow.png", offsetX: 10, offsetY: 10, width: 100, height: 100}
'@param x the x coordinate of the main image
'@param y the y coordinate of the main image
'@param VISIBLE_IMAGES an Integer array containing two values, which respectively specify the number of images on the left and right of the main image. Default is [3, 3]
function RlCarousel(images as Object, bigShadow as Object, smallShadow as Object, x as Integer, y as Integer, ANIMATION_TIME = 0.25 as Float, VISIBLE_IMAGES = [40, 40] as Object, WRAP_AROUND = false as Boolean) as Object
    this = {
        bigShadow: bigShadow
        smallShadow: smallShadow
        images: images
        x: x
        y: y
        
        moving: false
        reversed: false
        advance: false
        direction: 0
        index: 0
        
        DEFAULT_ANIMATION_TIME: ANIMATION_TIME
        'Constants
        ANIMATION_TIME: ANIMATION_TIME 'If the value is 0, then animation is instant
        VISIBLE_IMAGES: VISIBLE_IMAGES
        
        Init: RlCarousel_Init
        Move: RlCarousel_Move
        Draw: RlCarousel_Draw
        Update: RlCarousel_Update
    }
    
    
    this.Init()
    
    return this
end function

function RlCarousel_Init() as Void
    'Create visible shadows
    m.visibleShadows = []
    
    'Small shadow constants
    smallPath = m.smallShadow.path
    smallOffsetX = m.smallShadow.offsetX
    smallOffsetY = m.smallShadow.offsetY
    smallWidth = m.smallShadow.width
    smallHeight = m.smallShadow.height
    
    'Big shadow constants
    bigPath = m.bigShadow.path
    bigOffsetX = m.bigShadow.offsetX
    bigOffsetY = m.bigShadow.offsetY
    bigWidth = m.bigShadow.width
    bigHeight = m.bigShadow.height
    
    actualX = m.x - bigOffsetX 'Since the main shadow has an offset shadow border
    
    max = m.images.Count()
    'Initialize big shadow
    if max <> 0
        bigShadow = RlImage(bigPath, actualX, m.y, bigWidth, bigHeight)
        bigShadow.moveLeft = 0
        bigShadow.moveCurrent = 0
        bigShadow.moveTotal = 0
        bigShadow.scaleLeft = 1
        m.visibleShadows.Push(bigShadow)
        m.visibleImages = []
        
        'Initialize small shadows
        max = RlMin(m.VISIBLE_IMAGES[0] + m.VISIBLE_IMAGES[1] - 1, max - 2)
        for i = 0 to max
            shadow = RlImage(smallPath, actualX + bigWidth + i * smallWidth, m.y + (bigHeight - smallHeight) / 2, smallWidth, smallHeight)
            shadow.moveLeft = 0
            shadow.moveCurrent = 0
            shadow.moveTotal = 0
            shadow.scaleLeft = 1
            m.visibleShadows.Push(shadow)
        end for
    end if
    
    m.wrapLeftX = actualX - m.VISIBLE_IMAGES[0] * smallWidth
    m.wrapRightX = actualX + bigWidth + m.VISIBLE_IMAGES[1] * smallWidth 
end function

'Set this carousel to start moving to the next item (right) or previous item (left).
'@param direction the direction to move in. 1 for right and -1 for left. 0 stops the carousel
function RlCarousel_Move(direction as Integer) as Void
    'print "RlCarousel.Move()"
    'Small shadow constants
    smallPath = m.smallShadow.path
    smallOffsetX = m.smallShadow.offsetX
    smallOffsetY = m.smallShadow.offsetY
    smallWidth = m.smallShadow.width
    smallHeight = m.smallShadow.height
    
    'Big shadow constants
    bigPath = m.bigShadow.path
    bigOffsetX = m.bigShadow.offsetX
    bigOffsetY = m.bigShadow.offsetY
    bigWidth = m.bigShadow.width
    bigHeight = m.bigShadow.height
    actualX = m.x - bigOffsetX 'Since the main shadow has an offset shadow border
    
    if (direction = -1 and m.index > 0) or (direction = 1 and m.index < m.images.Count() - 1)
        'Calculate move amounts
        max = m.visibleShadows.Count() - 1
        for i = 0 to max
            shadow = m.visibleShadows[i]
            if direction = - m.direction 'Animation reversed direction
                shadow.moveLeft = RlModulo(shadow.moveCurrent, shadow.movePer) 'Reverse movement to the nearest previous item
                shadow.moveTotal = shadow.movePer
                'shadow.moveCurrent = shadow.moveTotal - shadow.moveLeft 'Reverse movement to the nearest previous item
                shadow.scaleTotal = 1 / shadow.scaleLeft
                m.reversed = true  
            else 'Continuing in same direction, or new direction
                if shadow.x = actualX 'Shadow is the big shadow
                    if direction = -1
                        shadow.moveTotal = bigWidth
                        shadow.scaleTotal = smallWidth / bigWidth
                    else if direction = 1
                        shadow.moveTotal = smallWidth
                        shadow.scaleTotal = smallWidth / bigWidth
                    end if
                else 'Shadow is the small shadow
                    if shadow.x = actualX + bigWidth and direction = 1 'To the right of the big shadow and moving left
                        shadow.moveTotal = bigWidth
                        shadow.scaleTotal = bigWidth / smallWidth
                    else if shadow.x = actualX - smallWidth and direction = -1 'To the left of the big shadow and moving right
                        shadow.moveTotal = smallWidth
                        shadow.scaleTotal = bigWidth / smallWidth
                    else 'All other shadows move the small width, and do not scale
                        shadow.moveTotal = smallWidth
                        shadow.scaleTotal = 1
                    end if
                end if
                
                if not m.moving 'Starting from 0
                    shadow.movePer = shadow.moveTotal
                    shadow.moveCurrent = 0
                    shadow.moveLeft = shadow.moveTotal
                else 'Adding to current direction
                    'shadow.moveCurrent = shadow.moveTotal - shadow.moveLeft
                    shadow.movePer = shadow.moveTotal 'Left/right movement of 1 unit
                    shadow.moveTotal = shadow.moveLeft + shadow.moveTotal
                    shadow.scaleTotal = shadow.scaleLeft * shadow.scaleTotal
                    shadow.scaleLeft = shadow.scaleTotal 
                    shadow.moveLeft = shadow.moveTotal
                    'Clamp move left to be however much movement is available
                    if direction = 1 
                        diff = m.images.Count() - 2 - m.index
                    else if direction = -1
                        diff = m.index - 1
                    end if
                    shadow.moveLeft = RlMin(shadow.moveLeft, RlModulo(shadow.moveLeft, shadow.movePer) + (diff * shadow.movePer))
                end if

            end if
        end for

        m.moving = true
        m.direction = direction
    end if
    
end function

'Update the carousel, independent of frame rate (since Roku 1/2/3 devices have different max framerates)
'@param delta the change in time value
'@return true if updated
function RlCarousel_Update(delta as Float) as Boolean
    if m.moving
        'print "RlCarousel.Update()"
        max = m.visibleShadows.Count() - 1
        'Move each shadow if animation time is nonzero
        for i = 0 to max
            shadow = m.visibleShadows[i]
            if shadow.moveLeft > 0
                if m.ANIMATION_TIME > 0 
                    moveAmount = int(- m.direction * delta * (shadow.moveTotal / m.ANIMATION_TIME))
                else
                    moveAmount = int(- m.direction * shadow.moveTotal)
                end if
                
                if abs(moveAmount) > shadow.moveLeft then moveAmount = - m.direction * shadow.moveLeft 'moveAmount greater than moveLeft, clamp it
                shadow.x = shadow.x + moveAmount
                shadow.moveCurrent = shadow.moveCurrent + abs(moveAmount)
                'print "Shadow.movecurrent: " + tostr(shadow.moveCurrent)
                'print "shadow.movper: " + tostr(shadow.movePer)                                 
                shadow.moveLeft = shadow.moveLeft - abs(moveAmount)
                
                m.moving = true
            else
                m.moving = false
            end if
        end for          
    
        shadow = m.visibleShadows[0]
        
        if shadow.moveCurrent >= shadow.movePer and not m.reversed 'I.e. moved past a single unit
            shadow.moveCurrent = 0 'Reset the position past a single unit to 0
            m.index = m.index + m.direction
            if m.index < 0 then m.index = 0
            imageMax = m.images.Count() - 1
            if m.index > imageMax then m.index = imageMax
        end if
        
        'Swap the positions of shadows (wrap around case) once they stopped moving
        temp = m.visibleShadows[0]
        if temp.x < m.wrapLeftX and m.index + m.VISIBLE_IMAGES[1] < m.images.Count() - 1 'Left wraparound
            temp.x = m.visibleShadows[max].x + m.visibleShadows[max].width
            for i = 0 to max - 1
                m.visibleShadows[i] = m.visibleShadows[i + 1]
            end for
            m.visibleShadows[max] = temp
        end if
        
        temp = m.visibleShadows[max]
        if temp.x > m.wrapRightX and m.index - m.VISIBLE_IMAGES[0] > 0 'Right wraparound
            temp.x = m.visibleShadows[0].x - temp.width
            for i = max to 1
                m.visibleShadows[i] = m.visibleShadows[i - 1]
            end for
            m.visibleShadows[0] = temp
        end if        
        return true
    else    
        m.reversed = false
        m.direction = 0
        return false
    end if
    
    return false
end function

'Draws this RlCarousel to the specified component.
'@param component a roScreen/roBitmap/roRegion object
'@return true if successful
function RlCarousel_Draw(component as Object) as Boolean
    if not RlDrawAll(m.visibleShadows, component) then return false
    return true
end function