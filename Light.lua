local Shadows = ...
local Light = {}

Light.__index = Light
Light.x, Light.y, Light.z = 0, 0, 0
Light.Angle = 0
Light.Radius = 0

Light.R, Light.G, Light.B, Light.A = 255, 255, 255, 255

Light.Shader = love.graphics.newShader [[
	extern vec3 Center;
	extern vec3 LightColor;
	extern float LightRadius;

	vec4 effect(vec4 Color, Image Texture, vec2 TextureCords, vec2 PixelCords){
		float Distance = length(vec3(PixelCords.x, PixelCords.y, 0.0) - Center);
		if (Distance <= LightRadius) {
			return vec4(LightColor, 1 - (Distance / LightRadius));
		}
		return vec4(0, 0, 0, 0);
	}
]]

function Shadows.CreateLight(World, Radius)
	local Light = setmetatable({}, Light)
	
	Light.Radius = Radius
	Light.Canvas = love.graphics.newCanvas(Light.Radius * 2, Light.Radius * 2)
	
	World:AddLight(Light)
	
	return Light
end

function Shadows.CreateStar(World, Radius)
	local Light = setmetatable({}, LightMT)
	
	Light.Radius = Radius
	Light.Canvas = love.graphics.newCanvas(Light.Radius * 2, Light.Radius * 2)
	
	World:AddStar(Light)
	
	return Light
end

function Light:GenerateShadows()
	local Shadows = {}
	for _, Body in pairs(self.World.Bodies) do
		for _, Shadow in pairs(Body:GenerateShadows(self)) do
			table.insert(Shadows, Shadow)
		end
	end
	return Shadows
end

function Light:Update()
	if self.Changed or self.World.Changed then
		love.graphics.setCanvas(self.Canvas)
		love.graphics.clear()
		
		if self.Image then
			-- self.Radius is the center of the canvas
			love.graphics.setBlendMode("lighten")
			love.graphics.setColor(self.R, self.G, self.B, self.A)
			love.graphics.draw(self.Image, self.Radius, self.Radius)
		else
			self.Shader:send("LightColor", {self.R, self.G, self.B})
			self.Shader:send("LightRadius", self.Radius)
			self.Shader:send("Center", {self.Radius, self.Radius, self.z})
			
			love.graphics.setShader(self.Shader)
			love.graphics.setBlendMode("alpha")
			love.graphics.setColor(255, 255, 255, 255)
			love.graphics.rectangle("fill", 0, 0, self.Radius * 2, self.Radius * 2)
			love.graphics.setShader()
		end
		
		love.graphics.setBlendMode("alpha")
		love.graphics.setColor(0, 0, 0, 255)
		love.graphics.translate(self.Radius - self.x, self.Radius - self.y)
		for _, Shadow in pairs(self:GenerateShadows()) do
			love.graphics[Shadow.type]("fill", unpack(Shadow))
		end
		
		love.graphics.setColor(255, 255, 255, 255)
		love.graphics.setBlendMode("subtract")
		love.graphics.draw(self.World.BodyCanvas, self.Radius - self.x, self.Radius - self.y)
		
		love.graphics.origin()
		love.graphics.setCanvas()
		
		self.Changed = nil
		self.World.UpdateCanvas = true
	end
end

function Light:SetAngle(Angle)
	if type(Angle) == "number" and Angle ~= self.Angle then
		self.Angle = Angle
		self.Changed = true
	end
end

function Light:GetAngle()
	return self.Angle
end

function Light:SetPosition(x, y, z)
	if x ~= self.x then
		self.x = x
		self.Changed = true
	end
	if y ~= self.y then
		self.y = y
		self.Changed = true
	end
	if z and z ~= self.z then
		self.z = z
		self.Changed = true
	end
end

function Light:GetPosition()
	return self.x, self.y, self.z
end

function Light:SetColor(R, G, B, A)
	if R ~= self.R then
		self.R = R
		self.Changed = true
	end
	if G ~= self.G then
		self.G = G
		self.Changed = true
	end
	if B ~= self.B then
		self.B = B
		self.Changed = true
	end
	if A ~= self.A then
		self.A = A
		self.Changed = true
	end
end

function Light:GetColor()
	return self.R, self.G, self.B, self.A
end

function Light:SetImage(Image)
	if Image ~= self.Image then
		self.Image = Image
		self.Radius = math.sqrt(Image:getWidth()^2 + Image:getHeight()^2) / 2
		self.Canvas = love.graphics.newCanvas(self.Radius * 2, self.Radius * 2)
		self.Changed = true
	end
end

function Light:GetImage()
	return self.Image
end

function Light:SetRadius(Radius)
	if Radius ~= self.Radius then
		self.Radius = Radius
		self.Canvas = love.graphics.newCanvas(self.Radius * 2, self.Radius * 2)
		self.Changed = true
	end
end

function Light:GetRadius()
	return self.Radius
end